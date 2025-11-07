//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class Foundation.NSRecursiveLock
import enum Smithy.ByteStream
import protocol Smithy.ResponseMessage
import protocol Smithy.Stream

public final class HTTPResponse: ResponseMessage, @unchecked Sendable {
    private var lock = NSRecursiveLock()

    private var _headers: Headers
    public var headers: Headers {
        get { lock.lock(); defer { lock.unlock() }; return _headers }
        set { lock.lock(); defer { lock.unlock() }; self._headers = newValue }
    }

    private var _body: ByteStream
    public var body: ByteStream {
        get { lock.lock(); defer { lock.unlock() }; return _body }
        set { lock.lock(); defer { lock.unlock() }; self._body = newValue }
    }

    private var _statusCode: HTTPStatusCode
    public var statusCode: HTTPStatusCode {
        get { lock.lock(); defer { lock.unlock() }; return _statusCode }
        set { lock.lock(); defer { lock.unlock() }; self._statusCode = newValue }
    }

    public let reason: String?

    public init(
        headers: Headers = .init(),
        statusCode: HTTPStatusCode = .processing,
        body: ByteStream = .noStream,
        reason: String? = nil
    ) {
        self._headers = headers
        self._statusCode = statusCode
        self._body = body
        self.reason = reason
    }

    public init(headers: Headers = .init(), body: ByteStream, statusCode: HTTPStatusCode, reason: String? = nil) {
        self._body = body
        self._statusCode = statusCode
        self._headers = headers
        self.reason = reason
    }

    /**
     * Replace the response body
     */
    public func copy(
        headers: Headers? = nil,
        body: ByteStream? = nil,
        statusCode: HTTPStatusCode? = nil,
        reason: String? = nil
    ) -> HTTPResponse {
        return HTTPResponse(
            headers: headers ?? self.headers,
            body: body ?? self.body,
            statusCode: statusCode ?? self.statusCode,
            reason: reason ?? self.reason
        )
    }
}

extension HTTPResponse: CustomDebugStringConvertible {
    public var debugDescriptionWithBody: String {
        return debugDescription + "\nResponseBody: \(body.debugDescription)"
    }
    public var debugDescription: String {
        return "\nStatus Code: \(statusCode.description) \n \(headers)"
    }
}
