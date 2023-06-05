//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AwsCommonRuntimeKit

public final class URLSessionHTTPClient: HttpClientEngine {

    class Connection {
        let readTimeout: TimeInterval = 30.0
        let writeTimeout: TimeInterval = 30.0
        let bufferSize = 4096
        var continuation: CheckedContinuation<HttpResponse, Error>?
        var urlSessionStreamTask: URLSessionStreamTask?
        var requestStream: ReadableStream?
        var requestStreamTask: Task<Void, Error>?
        var streamBridge: StreamBridge?
        var responseStream: WriteableStream?
        var responseStreamTask: Task<Void, Error>?

        init(continuation: CheckedContinuation<HttpResponse, Error>, requestStream: ReadableStream, streamBridge: StreamBridge) {
            self.continuation = continuation
            self.requestStream = requestStream
            self.streamBridge = streamBridge
        }

        func connectStreams() {
            print("CONNECTING STREAMS")
            self.requestStreamTask = Task {
                do {
                    while let data = try await requestStream?.readAsync(upToCount: bufferSize) {
                        print("READ \(data.count) BYTES FROM REQUEST")
                        try await urlSessionStreamTask?.write(data, timeout: writeTimeout)
                        print("WROTE \(data.count) BYTES TO REQUEST")
                    }
                    urlSessionStreamTask?.closeWrite()
                } catch {
                    urlSessionStreamTask?.closeWrite()
                }
            }
            self.responseStreamTask = Task {
                do {
                    var stop = false
                    while !stop, let (data, atEOF) = try await urlSessionStreamTask?.readData(ofMinLength: 0, maxLength: bufferSize, timeout: readTimeout) {
                        print("READ \(data?.count ?? 0) BYTES FROM RESPONSE")
                        try responseStream?.write(contentsOf: data ?? Data())
                        print("WROTE \(data?.count ?? 0) BYTES TO RESPONSE")
                        stop = atEOF
                    }
                    urlSessionStreamTask?.closeRead()
                } catch {
                    urlSessionStreamTask?.closeRead()
                }
            }
        }
    }

    final class Storage: @unchecked Sendable {
        private let lock = NSRecursiveLock()
        private var connections = [URLSessionTask: Connection]()

        subscript(_ key: URLSessionTask) -> Connection? {
            get {
                lock.lock()
                defer { lock.unlock() }
                let connection = connections[key]
                return connection
            }
            set {
                lock.lock()
                defer { lock.unlock() }
                connections[key] = newValue
            }
        }

        func modify(_ key: URLSessionTask, block: (inout Connection) -> Void) {
            lock.lock()
            defer { lock.unlock() }
            guard var connection = connections[key] else { return }
            block(&connection)
            connections[key] = connection
        }

        func remove(_ key: URLSessionTask) {
            lock.lock()
            defer { lock.unlock() }
            connections.removeValue(forKey: key)
        }
    }

    private final class SessionDelegate: NSObject, URLSessionTaskDelegate, URLSessionDataDelegate {
        let storage = Storage()

        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
            print("DID RECEIVE RESPONSE")
            defer { completionHandler(.becomeStream) }
            storage.modify(dataTask) { connection in
                guard let httpResponse = response as? HTTPURLResponse else {
                    let error = URLSessionHTTPClientError.responseNotHTTP
                    connection.continuation?.resume(throwing: error)
                    connection.continuation = nil
                    return
                }
                let statusCode = HttpStatusCode(rawValue: httpResponse.statusCode) ?? .insufficientStorage
                let httpHeaders: [HTTPHeader] = httpResponse.allHeaderFields.compactMap { (name, value) in
                    guard let name = name as? String else { return nil }
                    return HTTPHeader(name: name, value: String(describing: value))
                }
                let headers = Headers(httpHeaders: httpHeaders)
                let responseStream = BufferedStream()
                connection.responseStream = responseStream
                let body = HttpBody.stream(responseStream)
                let response = HttpResponse(headers: headers, body: body, statusCode: statusCode)
                connection.continuation?.resume(returning: response)
                connection.continuation = nil
            }
        }

        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didBecome streamTask: URLSessionStreamTask) {
            print("PROMOTED TO STREAM")
            let connection = storage[dataTask]
            connection?.urlSessionStreamTask = streamTask
            storage[streamTask] = connection
            storage.remove(dataTask)
            connection?.connectStreams()
        }

        func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
            storage.modify(task) { connection in
                if let error = error  {
                    if let continuation = connection.continuation {
                        continuation.resume(throwing: error)
                        connection.continuation = nil
                    } else {
                        connection.responseStream?.closeWithError(error)
                    }
                } else {
                    connection.responseStream?.close()
                }
            }
            storage.remove(task)
        }
    }

    let session: URLSession
    private let delegate: SessionDelegate

    public init() {
        self.delegate = SessionDelegate()
        self.session = URLSession(configuration: .default, delegate: self.delegate, delegateQueue: nil)
    }

    public func execute(request: SdkHttpRequest) async throws -> HttpResponse {
        var outputStream: OutputStream?
        var inputStream: InputStream?
        Foundation.Stream.getBoundStreams(withBufferSize: 4096, inputStream: &inputStream, outputStream: &outputStream)
        let urlRequest = try await makeURLRequest(from: request, inputStream: inputStream!)
        let dataTask = session.dataTask(with: urlRequest)
        return try await withCheckedThrowingContinuation { continuation in
            let requestStream: ReadableStream
            switch request.body {
            case .data(let data):
                requestStream = BufferedStream(data: data, isClosed: true)
            case .stream(let stream):
                requestStream = stream
            case .none:
                requestStream = BufferedStream(data: Data(), isClosed: true)
            }
            let streamBridge = StreamBridge(readableStream: requestStream, outputStream: outputStream!)
            delegate.storage[dataTask] = Connection(continuation: continuation, requestStream: requestStream, streamBridge: streamBridge)
            dataTask.resume()
            inputStream?.open()
            streamBridge.open()
        }
    }

    private func makeURLRequest(from request: SdkHttpRequest, inputStream: InputStream) async throws -> URLRequest {
        var components = URLComponents()
        components.scheme = request.endpoint.protocolType?.rawValue ?? "https"
        components.host = request.endpoint.host
        components.percentEncodedPath = request.path
        components.percentEncodedQueryItems = request.queryItems?.map { Foundation.URLQueryItem(name: $0.name, value: $0.value) }
        var urlRequest = URLRequest(url: components.url!)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.httpShouldUsePipelining = true
        urlRequest.httpBodyStream = inputStream
        for header in request.headers.headers {
            for value in header.value {
                urlRequest.addValue(value, forHTTPHeaderField: header.name)
            }
        }
        return urlRequest
    }
}

public enum URLSessionHTTPClientError: Error {
    case responseNotHTTP
}

class StreamBridge: NSObject, StreamDelegate {
    let readableStream: ReadableStream
    let outputStream: OutputStream
    private var buffer = Data()

    init(readableStream: ReadableStream, outputStream: OutputStream) {
        self.readableStream = readableStream
        self.outputStream = outputStream
    }

    func open() {
        outputStream.delegate = self
        outputStream.open()
        Task {
            try await writeToOutput()
        }
    }

    func writeToOutput() async throws {
        let data = try await readableStream.readAsync(upToCount: 4096 - buffer.count)
        guard let data = data, buffer.count > 0 else {
            outputStream.close()
            return
        }
        buffer.append(data)
        withUnsafePointer(to: buffer) { ptr in
            let result = outputStream.write(ptr, maxLength: data.count)
            if result > 0 {
                buffer.removeFirst(result)
            }
        }
    }

    func stream(_ aStream: Foundation.Stream, handle eventCode: Foundation.Stream.Event) {
        switch eventCode {
        case .openCompleted:
            print("openCompleted")
        case .hasSpaceAvailable:
            print("hasSpaceAvailable")
            Task {
                try await writeToOutput()
            }
        case .hasBytesAvailable:
            print("hasBytesAvailable")
        case .endEncountered:
            print("endEncountered")
        case .errorOccurred:
            print("errorOccurred")
        default:
            break
        }
    }
}
