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

public class HttpResponse: HttpUrlResponse, ResponseMessage {

    public var headers: Headers
    public var body: ByteStream
    public var reason: String?

    private var _statusCode: HttpStatusCode
    private let statusCodeQueue = DispatchQueue(label: "statusCodeSerialQueue")
    public var statusCode: HttpStatusCode {
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
        statusCode: HttpStatusCode = .processing,
        body: ByteStream = .noStream,
        reason: String? = nil) {
        self.headers = headers
        self._statusCode = statusCode
        self.body = body
    }

    public init(headers: Headers = .init(), body: ByteStream, statusCode: HttpStatusCode, reason: String? = nil) {
        self.body = body
        self._statusCode = statusCode
        self.headers = headers
    }
}

extension HttpResponse: CustomDebugStringConvertible {
    public var debugDescriptionWithBody: String {
        return debugDescription + "\nResponseBody: \(body.debugDescription)"
    }
    public var debugDescription: String {
        return "\nStatus Code: \(statusCode.description) \n \(headers)"
    }
}
