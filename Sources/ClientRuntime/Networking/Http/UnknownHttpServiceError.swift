/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import SmithyHTTPAPI

/// General Service Error structure used when exact error could not be deduced from the `HttpResponse`
public struct UnknownHTTPServiceError: ServiceError, HTTPError, Error {
    public var typeName: String?

    public var message: String?

    public var httpResponse: HttpResponse
}

extension UnknownHTTPServiceError {

    /// Creates an `UnknownHTTPServiceError` from a HTTP response.
    /// - Parameters:
    ///   - httpResponse: The `HttpResponse` for this error.
    ///   - message: The message associated with this error. Defaults to `nil`.
    ///   - errorType: The error type associated with this error.  Defaults to `nil`.
    public init(httpResponse: HttpResponse, message: String? = nil, typeName: String? = nil) {
        self.typeName = typeName
        self.httpResponse = httpResponse
        self.message = message
    }
}

extension UnknownHTTPServiceError {

    public static func makeError<Base: BaseError>(
        baseError: Base
    ) throws -> Error {
        UnknownHTTPServiceError(
            httpResponse: baseError.httpResponse,
            message: baseError.message,
            typeName: baseError.code
        )
    }
}
