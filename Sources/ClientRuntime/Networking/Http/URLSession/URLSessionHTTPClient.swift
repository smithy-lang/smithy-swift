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
        let bufferSize = 1024
        var continuation: CheckedContinuation<HttpResponse, Error>?
        var urlSessionDataTask: URLSessionDataTask?
        var urlSessionStreamTask: URLSessionStreamTask?
        var requestStreamTask: Task<Void, Error>?
        var responseStreamTask: Task<Void, Error>?
        var requestStream: ReadableStream?
        var streamBridge: OutputStreamBridge?
        var responseStream: WriteableStream?
        let bidirectional: Bool

        init(continuation: CheckedContinuation<HttpResponse, Error>, requestStream: ReadableStream, streamBridge: OutputStreamBridge?, bidirectional: Bool) {
            self.continuation = continuation
            self.requestStream = requestStream
            self.streamBridge = streamBridge
            self.bidirectional = bidirectional
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

    private final class SessionDelegate: NSObject, URLSessionTaskDelegate, URLSessionDataDelegate, URLSessionStreamDelegate {
        let storage = Storage()

        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
            print("URLSESSION DID RECEIVE RESPONSE")
            storage.modify(dataTask) { connection in
                defer { completionHandler(connection.bidirectional ? .becomeStream : .allow) }
                guard let httpResponse = response as? HTTPURLResponse else {
                    let error = URLSessionHTTPClientError.responseNotHTTP
                    connection.continuation?.resume(throwing: error)
                    connection.continuation = nil
                    return
                }
                print("HTTP CODE \(httpResponse.statusCode)")
                let statusCode = HttpStatusCode(rawValue: httpResponse.statusCode) ?? .insufficientStorage
                let httpHeaders: [HTTPHeader] = httpResponse.allHeaderFields.compactMap { (name, value) in
                    guard let name = name as? String else { return nil }
                    return HTTPHeader(name: name, value: String(describing: value))
                }
                print("HEADERS: \(httpResponse.allHeaderFields)")
                let headers = Headers(httpHeaders: httpHeaders)
                let responseStream = BufferedStream()
                connection.responseStream = responseStream
                let body = ByteStream.stream(responseStream)
                let response = HttpResponse(headers: headers, body: body, statusCode: statusCode)
                connection.continuation?.resume(returning: response)
                connection.continuation = nil
            }
        }

        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didBecome streamTask: URLSessionStreamTask) {
            print("URLSESSION PROMOTED TO STREAM")
            guard let connection = storage[dataTask] else { return }
            connection.urlSessionStreamTask = streamTask
            connection.urlSessionDataTask = nil
            storage[streamTask] = connection
            storage.remove(dataTask)
//            Task {
//                while let data = try await connection.requestStream?.readAsync(upToCount: 4096) {
//                    print("WRITING \(data.count) BYTES TO SERVER")
//                    try await streamTask.write(data, timeout: 30.0)
//                }
//            }
            Task {
                var data: Data? = nil
                var atEOF = false
                while !atEOF {
                    if let data = data {
                        try connection.responseStream?.write(contentsOf: data)
                    }
                    let (incomingData, eof) = try await streamTask.readData(ofMinLength: 0, maxLength: 4096, timeout: 30.0)
                    print("READ \(incomingData?.count ?? 0) BYTES FROM SERVER")
                    if eof { print("EOF REACHED") }
                    data = incomingData ?? Data()
                    atEOF = eof
                }
                connection.responseStream?.close()
            }
        }

        func urlSession(_ session: URLSession, readClosedFor streamTask: URLSessionStreamTask) {
            print("URLSESSION READ CLOSED")
        }

        func urlSession(_ session: URLSession, writeClosedFor streamTask: URLSessionStreamTask) {
            print("URLSESSION WRITE CLOSED")
        }

        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
            print("URLSESSION RECEIVED \(data.count) BYTES")
            storage.modify(dataTask) { connection in
                try! connection.responseStream?.write(contentsOf: data)
            }
        }

        func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
            print("URLSESSION DID COMPLETE, ERROR: \(error != nil)")
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
        let config = URLSessionConfiguration.default
        config.httpShouldUsePipelining = false
        self.session = URLSession(configuration: config, delegate: self.delegate, delegateQueue: nil)
    }

    public func execute(request: SdkHttpRequest, bidirectional: Bool) async throws -> HttpResponse {
        var outputStream: OutputStream?
        var inputStream: InputStream?
        Foundation.Stream.getBoundStreams(withBufferSize: 4096, inputStream: &inputStream, outputStream: &outputStream)
        guard let inputStream, let outputStream else { throw URLSessionHTTPClientError.FoundationStreamError }
        return try await withCheckedThrowingContinuation { continuation in
            let initialStream: ReadableStream
            let requestStream: ReadableStream
            let urlRequest: URLRequest
            switch request.body {
            case .data(let data):
                requestStream = BufferedStream(data: data, isClosed: true)
                initialStream = requestStream
                urlRequest = makeURLRequest(from: request, inputStream: inputStream)
            case .stream(let stream):
//                initialStream = bidirectional ? BufferedStream(data: nil, isClosed: true) : stream
                initialStream = stream
                requestStream = stream
                urlRequest = makeURLRequest(from: request, inputStream: inputStream)
            case .noStream:
                requestStream = BufferedStream(data: nil, isClosed: true)
                initialStream = requestStream
                urlRequest = makeURLRequest(from: request, inputStream: nil)
            }
            print("URLREQUEST CONTENTS")
            print("\(urlRequest.debugDescription)")
            let streamBridge: OutputStreamBridge?
            streamBridge = OutputStreamBridge(readableStream: initialStream, outputStream: outputStream)
            let dataTask = session.dataTask(with: urlRequest)
            delegate.storage[dataTask] = Connection(continuation: continuation, requestStream: requestStream, streamBridge: streamBridge, bidirectional: bidirectional)
            dataTask.resume()
            streamBridge?.open()
        }
    }

    private func makeURLRequest(from request: SdkHttpRequest, inputStream: InputStream?) -> URLRequest {
        var components = URLComponents()
        components.scheme = request.endpoint.protocolType?.rawValue ?? "https"
        components.host = request.endpoint.host
        components.percentEncodedPath = request.path
        let queryItems: [Foundation.URLQueryItem]? = (request.queryItems?.isEmpty ?? true) ? nil : request.queryItems?.map { Foundation.URLQueryItem(name: $0.name, value: $0.value) }
        components.percentEncodedQueryItems = queryItems
        var urlRequest = URLRequest(url: components.url!)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.httpBodyStream = inputStream
        urlRequest.httpShouldUsePipelining = false
        for header in request.headers.headers {
            for value in header.value {
                urlRequest.addValue(value, forHTTPHeaderField: header.name)
            }
        }
        urlRequest.setValue("chunked", forHTTPHeaderField: "Transfer-Encoding")
        return urlRequest
    }
}

public enum URLSessionHTTPClientError: Error {
    case FoundationStreamError
    case responseNotHTTP
}
