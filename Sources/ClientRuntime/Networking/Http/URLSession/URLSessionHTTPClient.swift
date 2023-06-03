//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AwsCommonRuntimeKit

public final class URLSessionHTTPClient: HttpClientEngine {

    struct Connection {
        var continuation: CheckedContinuation<HttpResponse, Error>?
        var stream: WriteableStream?
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
            defer { completionHandler(.allow) }
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
                let stream = BufferedStream()
                connection.stream = stream
                let body = HttpBody.stream(stream)
                let response = HttpResponse(headers: headers, body: body, statusCode: statusCode)
                connection.continuation?.resume(returning: response)
                connection.continuation = nil
            }
        }

        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
            guard let connection = storage[dataTask] else { return }
            do {
                try connection.stream?.write(contentsOf: data)
            } catch {
                connection.stream?.closeWithError(error)
                dataTask.cancel()
            }
        }

        func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
            storage.modify(task) { connection in
                if let error = error  {
                    if let continuation = connection.continuation {
                        continuation.resume(throwing: error)
                        connection.continuation = nil
                    } else {
                        connection.stream?.closeWithError(error)
                    }
                } else {
                    connection.stream?.close()
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
        let urlRequest = try await makeURLRequest(from: request)
        let dataTask = session.dataTask(with: urlRequest)
        return try await withCheckedThrowingContinuation { continuation in
            delegate.storage[dataTask] = Connection(continuation: continuation)
            dataTask.resume()
        }
    }

    private func makeURLRequest(from request: SdkHttpRequest) async throws -> URLRequest {
        var components = URLComponents()
        components.scheme = request.endpoint.protocolType?.rawValue ?? "https"
        components.host = request.endpoint.host
        components.percentEncodedPath = request.path
        components.percentEncodedQueryItems = request.queryItems?.map { Foundation.URLQueryItem(name: $0.name, value: $0.value) }
        var urlRequest = URLRequest(url: components.url!)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.httpBody = try await request.body.readData()
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
