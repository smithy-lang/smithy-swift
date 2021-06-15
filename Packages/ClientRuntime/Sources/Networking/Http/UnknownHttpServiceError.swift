/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

/// General Service Error structure used when exact error could not be deduced from the `HttpResponse`
public struct UnknownHttpServiceError: HttpServiceError {
    public var _statusCode: HttpStatusCode?
    
    public var _headers: Headers?
    
    public var _message: String?
    
    public var _retryable: Bool = false
    
    public var _type: ErrorType = .unknown
}

extension UnknownHttpServiceError {
    public init(httpResponse: HttpResponse, message: String? = nil) {
        self._statusCode = httpResponse.statusCode
        self._headers = httpResponse.headers
        self._message = message
    }
}
