//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AwsCommonRuntimeKit

public final class URLSessionHTTPClient: HttpClientEngine {

    final class Connection {
        let streamBridge: FoundationStreamBridge?
        var continuation: CheckedContinuation<HttpResponse, Error>?
        var error: Error?
        let responseStream = BufferedStream()

        init(streamBridge: FoundationStreamBridge?, continuation: CheckedContinuation<HttpResponse, Error>) {
            self.streamBridge = streamBridge
            self.continuation = continuation
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

        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse) async -> URLSession.ResponseDisposition {
            print("URLSESSION DID RECEIVE RESPONSE")
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
                let body = ByteStream.stream(connection.responseStream)
                let response = HttpResponse(headers: headers, body: body, statusCode: statusCode)
                connection.continuation?.resume(returning: response)
                connection.continuation = nil
            }
            return .allow
        }

        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
            print("URLSESSION RECEIVED \(data.count) BYTES")
            storage.modify(dataTask) { connection in
                do {
                    try connection.responseStream.write(contentsOf: data)
                } catch {
                    connection.error = error
                    dataTask.cancel()
                }
            }
        }

        func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
            print("URLSESSION DID COMPLETE, ERROR: \(error != nil)")
            storage.modify(task) { connection in
                if let error = connection.error ?? error {
                    if let continuation = connection.continuation {
                        continuation.resume(throwing: error)
                        connection.continuation = nil
                    } else {
                        connection.responseStream.closeWithError(error)
                    }
                } else {
                    connection.responseStream.close()
                }
                connection.streamBridge?.close()
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
        return try await withCheckedThrowingContinuation { continuation in
            let requestStream: ReadableStream? = switch request.body {
            case .data(let data):
                BufferedStream(data: data, isClosed: true)
            case .stream(let stream):
                stream
            case .noStream:
                nil
            }
            let streamBridge = requestStream.map { FoundationStreamBridge(readableStream: $0) }
            let urlRequest = makeURLRequest(from: request, httpBodyStream: streamBridge?.foundationInputStream)
            let dataTask = session.dataTask(with: urlRequest)
            delegate.storage[dataTask] = Connection(streamBridge: streamBridge, continuation: continuation)
            dataTask.resume()
            streamBridge?.open()
        }
    }

    private func makeURLRequest(from request: SdkHttpRequest, httpBodyStream: InputStream?) -> URLRequest {
        var components = URLComponents()
        components.scheme = request.endpoint.protocolType?.rawValue ?? "https"
        components.host = request.endpoint.host
        components.percentEncodedPath = request.path
        if let queryItems = request.queryItems, !queryItems.isEmpty {
            components.percentEncodedQueryItems = queryItems.map {
                Foundation.URLQueryItem(name: $0.name, value: $0.value)
            }
        }
        guard let url = components.url else { fatalError("Invalid HTTP request.  Please file a bug to report this.") }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.httpBodyStream = httpBodyStream
        for header in request.headers.headers {
            for value in header.value {
                urlRequest.addValue(value, forHTTPHeaderField: header.name)
            }
        }
        return urlRequest
    }
}

/// Errors that are particular to the URLSession-based AWS HTTP client.
/// Please file a bug with aws-sdk-swift if you experience any of these errors.
public enum URLSessionHTTPClientError: Error {
    case FoundationStreamError
    case responseNotHTTP
}
