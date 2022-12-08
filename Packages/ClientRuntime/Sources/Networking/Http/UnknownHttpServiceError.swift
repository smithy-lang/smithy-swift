/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

/// General Service Error structure used when exact error could not be deduced from the `HttpResponse`
public struct UnknownHttpServiceError: HttpServiceError, Swift.Equatable {
    public var _errorCode: String?

    public var _isThrottling: Bool = false
    
    public var _statusCode: HttpStatusCode?
    
    public var _headers: Headers?
    
    public var _message: String?
    
    public var _retryable: Bool = false
    
    public var _type: ErrorType = .unknown
}

extension UnknownHttpServiceError {


    /// Creates an `UnknownHttpServiceError` from a HTTP response.
    /// - Parameters:
    ///   - httpResponse: The `HttpResponse` for this error.
    ///   - message: The message associated with this error. Defaults to nil
    ///   - errorCode: The error code associated with this error.  Defaults to nil
    public init(httpResponse: HttpResponse, message: String? = nil, errorCode: String? = nil) {
        self._statusCode = httpResponse.statusCode
        self._headers = httpResponse.headers
        self._message = message
        self._errorCode = errorCode
    }
}

extension UnknownHttpServiceError: CodedError {

    /// The error code for this error, or `nil` if the code could not be determined.
    /// How this code is determined depends on the Smithy protocol used to decode the response.
    public var errorCode: String? { _errorCode }
}
