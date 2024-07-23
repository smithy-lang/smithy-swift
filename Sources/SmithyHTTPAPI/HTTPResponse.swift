//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import protocol Smithy.ResponseMessage
import protocol Smithy.Stream
import enum Smithy.ByteStream
import class Foundation.DispatchQueue

public class HTTPResponse: HTTPURLResponse, ResponseMessage {

    public var headers: Headers
    public var body: ByteStream
    public var reason: String?

    private var _statusCode: HTTPStatusCode
    private let statusCodeQueue = DispatchQueue(label: "statusCodeSerialQueue")
    public var statusCode: HTTPStatusCode {
        get {
            statusCodeQueue.sync {
                return _statusCode
            }
        }
        set {
            statusCodeQueue.sync {
                self._statusCode = newValue
            }
        }
    }

    public init(
        headers: Headers = .init(),
        statusCode: HTTPStatusCode = .processing,
        body: ByteStream = .noStream,
        reason: String? = nil) {
        self.headers = headers
        self._statusCode = statusCode
        self.body = body
    }

    public init(headers: Headers = .init(), body: ByteStream, statusCode: HTTPStatusCode, reason: String? = nil) {
        self.body = body
        self._statusCode = statusCode
        self.headers = headers
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
