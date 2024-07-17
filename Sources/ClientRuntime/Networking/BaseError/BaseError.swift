//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class SmithyHTTPAPI.HTTPResponse

public protocol BaseError {
    var httpResponse: HTTPResponse { get }
    var code: String { get }
    var message: String? { get }
    var requestID: String? { get }

    func customError() -> Error?
}

public extension BaseError {

    /// Returns a custom error from the error response, if any.
    ///
    /// By default, a `BaseError` returns no custom error unless
    /// the implementation provides its own implementation of this method.
    /// - Returns: Some custom `Error` or `nil` if none.
    func customError() -> Error? { nil }
}

public enum BaseErrorDecodeError: Error {
    case missingRequiredData
}
