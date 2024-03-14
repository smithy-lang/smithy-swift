//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(macOS) || os(watchOS) || os(tvOS) || os(visionOS)

import class Foundation.InputStream
import class Foundation.NSObject
import class Foundation.NSRecursiveLock
import struct Foundation.URLComponents
import struct Foundation.URLQueryItem
import struct Foundation.URLRequest
import class Foundation.URLResponse
import class Foundation.HTTPURLResponse
import class Foundation.URLSession
import class Foundation.URLSessionConfiguration
import class Foundation.URLSessionTask
import class Foundation.URLSessionDataTask
import protocol Foundation.URLSessionDataDelegate
import AwsCommonRuntimeKit

/// A client that can be used to make requests to AWS services using `Foundation`'s `URLSession` HTTP client.
///
/// This client is usable on all Swift platforms that support both the `URLSession` library and Objective-C interoperability features
/// (these are generally the Apple platforms.)
///
/// Use of this client is recommended on all Apple platforms, and is required on Apple Watch ( see
/// [TN3135: Low-level networking on watchOS](https://developer.apple.com/documentation/technotes/tn3135-low-level-networking-on-watchos)
/// for details about allowable modes of networking on the Apple Watch platform.)
///
/// On Linux platforms, we recommend using the CRT-based HTTP client for its configurability and performance.
public final class URLSessionHTTPClient: HTTPClient {

    /// Holds a connection's associated resources from the time the connection is executed to when it completes.
    private final class Connection {

        /// The `FoundationStreamBridge` for the request body, if any.
        ///
        /// This reference is stored with the connection so that it may be closed (and its resources disposed of)
        /// if the connection fails.
        let streamBridge: FoundationStreamBridge?

        /// The continuation for the asynchronous call that was made to initiate this request.
        ///
        /// Once the initial response is received, the continuation is called, and is subsequently set to `nil` so its
        /// resources may be deallocated.
        var continuation: CheckedContinuation<HttpResponse, Error>?

        /// Any error received during a delegate callback for this request.
        ///
        /// The stored error is thrown back to the caller once the URLSessionDelegate receives
        /// `urlSession(_:task:didCompleteWithError)` for this connection.
        var error: Error?

        /// A response stream that streams the response back to the caller.  Data is buffered in-memory until read by the caller.
        let responseStream = BufferedStream()

        /// Creates a new connection object
        /// - Parameters:
        ///   - streamBridge: The `FoundationStreamBridge` for the connection.
        ///   - continuation: The continuation object for the `execute(request:)` call that initiated this connection.
        init(streamBridge: FoundationStreamBridge?, continuation: CheckedContinuation<HttpResponse, Error>) {
            self.streamBridge = streamBridge
            self.continuation = continuation
        }
    }

    /// Provides thread-safe associative storage of `Connection`s keyed by their `URLSessionDataTask`.
    private final class Storage: @unchecked Sendable {

        /// Ensure all continuations are resumed before deallocation.
        ///
        /// This should never happen in practice but is being done defensively.
        deinit {
            connections.values.forEach {
                $0.continuation?.resume(throwing: URLSessionHTTPClientError.unresumedConnection)
            }
        }

        /// Lock used to enforce exclusive access to this `Storage` object.
        private let lock = NSRecursiveLock()

        /// A dictionary of `Connection`s, keyed by the `URLSessionTask` associated with them.
        private var connections = [URLSessionTask: Connection]()

        /// Adds a connection to the storage, keyed by its `URLSessionTask`.
        func set(_ connection: Connection, for key: URLSessionTask) {
            lock.lock()
            defer { lock.unlock() }
            connections[key] = connection
        }

        /// Allows modification of a `Connection` while holding exclusive access to it.
        ///
        /// Do not keep a reference to the connection outside the scope of `block`, or modify the connection after `block` returns.
        func modify(_ key: URLSessionTask, block: (Connection) -> Void) {
            lock.lock()
            defer { lock.unlock() }
            guard let connection = connections[key] else { return }
            block(connection)
        }

        /// Removes the connection keyed by `key` from storage.
        func remove(_ key: URLSessionTask) {
            lock.lock()
            defer { lock.unlock() }
            connections.removeValue(forKey: key)
        }
    }

    /// Handles URLSession delegate callbacks.
    private final class SessionDelegate: NSObject, URLSessionDataDelegate {

        /// Holds connection records for all in-progress connections.
        let storage = Storage()

        /// Logger for HTTP-related events.
        let logger: LogAgent

        init(logger: LogAgent) {
            self.logger = logger
        }

        /// Called when the initial response to a HTTP request is received.
        /// This callback is made as soon as the initial response + headers is complete.
        /// Response body data may continue to stream in after this callback is received.
        func urlSession(
            _ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse
        ) async -> URLSession.ResponseDisposition {
            logger.debug("urlSession(_:dataTask:didReceive:) called")
            storage.modify(dataTask) { connection in
                guard let httpResponse = response as? HTTPURLResponse else {
                    logger.error("Received non-HTTP urlResponse")
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

        /// Called when response data is received.
        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
            logger.debug("urlSession(_:dataTask:didReceive:) called with \(data.count) bytes")
            storage.modify(dataTask) { connection in
                do {
                    try connection.responseStream.write(contentsOf: data)
                } catch {
                    connection.error = error
                    dataTask.cancel()
                }
            }
        }

        /// Called when a HTTP request completes, either successfully or not.
        /// If an error occurs, it will be returned here.
        /// If the error is returned prior to the initial response, the request fails with an error.
        /// If the error is returned after the initial response, the error is used to fail the response stream.
        func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
            logger.debug("urlSession(_:task:didCompleteWithError:) called. \(error == nil ? "Success" : "Failure")")
            if let error { logger.debug("  Error: \(error.localizedDescription)") }
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

                // Close the stream bridge so that its resources are deallocated
                Task { await connection.streamBridge?.close() }
            }

            // Task is complete & no longer needed.  Remove it from storage.
            storage.remove(task)
        }
    }

    /// The `HttpClientConfiguration` for this HTTP client.
    let config: HttpClientConfiguration

    /// The `URLSession` used to perform HTTP requests.
    let session: URLSession

    /// The delegate object used to handle `URLSessionTask` callbacks.
    private let delegate: SessionDelegate

    /// The logger for this HTTP client.
    private var logger: LogAgent

    // MARK: - init & deinit

    /// Creates a new `URLSessionHTTPClient`.
    ///
    /// The client is created with its own internal `URLSession`, which is configured with system defaults and with a private delegate for handling
    /// URL task lifecycle events.
    /// - Parameter urlsessionConfiguration: The configuration to use for the client's `URLSession`.
    public init(httpClientConfiguration: HttpClientConfiguration) {
        self.config = httpClientConfiguration
        self.logger = SwiftLogger(label: "URLSessionHTTPClient")
        self.delegate = SessionDelegate(logger: logger)
        var urlsessionConfiguration = URLSessionConfiguration.default
        urlsessionConfiguration = URLSessionConfiguration.from(httpClientConfiguration: httpClientConfiguration)
        self.session = URLSession(configuration: urlsessionConfiguration, delegate: delegate, delegateQueue: nil)
    }

    /// On deallocation, finish any in-process tasks before disposing of the `URLSession`.
    deinit {
        session.finishTasksAndInvalidate()
    }

    // MARK: - HttpClientEngine protocol

    /// Executes the passed HTTP request using Foundation's `URLSession` HTTP client.
    ///
    /// The request is converted to a `URLRequest`, and (if required) the streaming body is bridged to a Foundation `InputStream` and streamed to
    /// the remote server.
    /// - Parameter request: The request to be submitted to the server.  Fields must be filled in sufficiently to form a valid URL.
    /// - Returns: The response to the request.  This call may return as soon as a complete response is received but before the body finishes streaming;
    /// the response body will continue to stream back to the caller.
    public func send(request: SdkHttpRequest) async throws -> HttpResponse {
        return try await withCheckedThrowingContinuation { continuation in

            // Get the request stream to use for the body, if any.
            let requestStream: ReadableStream?
            switch request.body {
            case .data(let data):
                requestStream = BufferedStream(data: data, isClosed: true)
            case .stream(let stream):
                requestStream = stream
            case .noStream:
                requestStream = nil
            }

            // Determine the proper environment variables to pass to FoundationStreamBridge
            var bufferSize = 4096
            var isChunkedTransfer = false
            if request.isChunked {
                bufferSize = CHUNK_SIZE_BYTES
                isChunkedTransfer = true
            }

            // If needed, create a stream bridge that streams data from a SDK stream to a Foundation InputStream
            // that URLSession can stream its request body from.
            let streamBridge = requestStream.map {
                FoundationStreamBridge(
                    readableStream: $0,
                    bufferSize: bufferSize,
                    isChunkedTransfer: isChunkedTransfer
                )
            }

            // Create the request (with a streaming body when needed.)
            let urlRequest = self.makeURLRequest(from: request, httpBodyStream: streamBridge?.inputStream)

            // Create the data task and associated connection object, then place them in storage.
            let dataTask = session.dataTask(with: urlRequest)
            let connection = Connection(streamBridge: streamBridge, continuation: continuation)
            delegate.storage.set(connection, for: dataTask)

            // Start the HTTP connection and start streaming the request body data
            dataTask.resume()
            Task {
                await streamBridge?.open()
                if request.isChunked {
                    do {
                        try await sendAwsChunkedBody(request: request) { chunk, isFinalChunk in
                            try await streamBridge?.handleChunk(chunk, isEndOfStream: isFinalChunk)
                        }
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }

    // MARK: - Private methods

    /// Create a `URLRequest` for the Smithy operation to be performed.
    /// - Parameters:
    ///   - request: The SDK-native, signed `SdkHttpRequest` ready to be transmitted.
    ///   - httpBodyStream: A Foundation `InputStream` carrying the HTTP body for this request.
    /// - Returns: A `URLRequest` ready to be transmitted by `URLSession` for this operation.
    private func makeURLRequest(from request: SdkHttpRequest, httpBodyStream: InputStream?) -> URLRequest {
        var components = URLComponents()
        components.scheme = config.protocolType?.rawValue ?? request.endpoint.protocolType?.rawValue ?? "https"
        components.host = request.endpoint.host
        components.port = port(for: request)
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
        for header in request.headers.headers + config.defaultHeaders.headers {
            for value in header.value {
                urlRequest.addValue(value, forHTTPHeaderField: header.name)
            }
        }
        return urlRequest
    }

    private func port(for request: SdkHttpRequest) -> Int? {
        switch (request.endpoint.protocolType, request.endpoint.port) {
        case (.https, 443), (.http, 80):
            // Don't set port explicitly if it's the default port for the scheme
            return nil
        default:
            return Int(request.endpoint.port)
        }
    }
}

/// Errors that are particular to the URLSession-based Smithy HTTP client.
public enum URLSessionHTTPClientError: Error {

    /// A non-HTTP response was returned by the server.
    /// Please file a bug with aws-sdk-swift if you experience this error.
    case responseNotHTTP

    /// A connection was not ended
    /// Please file a bug with aws-sdk-swift if you experience this error.
    case unresumedConnection
}

#endif
