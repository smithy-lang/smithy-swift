//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// The interface for creating the response object that results from a HTTP/HTTPS error response.
///
/// Value returned may be of any type that is a Swift `Error`.
public protocol HttpResponseErrorBinding {

    /// The interface for creating the response object that results from a HTTP/HTTPS error response.
    ///
    /// Value returned may be of any type that is a Swift `Error`.
    static func makeError(httpResponse: HttpResponse, decoder: ResponseDecoder?) async throws -> Error
}
