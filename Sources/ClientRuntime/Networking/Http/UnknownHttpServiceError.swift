/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

/// General Service Error structure used when exact error could not be deduced from the `HttpResponse`
public struct UnknownHttpServiceError: HttpServiceError, Swift.Equatable {
    public var _errorType: String?

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
    ///   - message: The message associated with this error. Defaults to `nil`.
    ///   - errorType: The error type associated with this error.  Defaults to `nil`.
    public init(httpResponse: HttpResponse, message: String? = nil, errorType: String? = nil) {
        self._statusCode = httpResponse.statusCode
        self._headers = httpResponse.headers
        self._message = message
        self._errorType = errorType
    }
}

extension UnknownHttpServiceError: WaiterTypedError {

    /// The Smithy identifier, without namespace, for the type of this error, or `nil` if the
    /// error has no known type.
    public var waiterErrorType: String? { _errorType }
}
