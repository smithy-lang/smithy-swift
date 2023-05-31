/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
import AwsCommonRuntimeKit

public class HttpResponse: HttpUrlResponse {

    public var headers: Headers
    public var body: HttpBody
    public var statusCode: HttpStatusCode

    public init(headers: Headers = Headers(),
         statusCode: HttpStatusCode = HttpStatusCode.processing,
         body: HttpBody = HttpBody.none) {
        self.headers = headers
        self.statusCode = statusCode
        self.body = body
    }

    public init(headers: Headers = Headers(), body: HttpBody, statusCode: HttpStatusCode) {
        self.body = body
        self.statusCode = statusCode
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
