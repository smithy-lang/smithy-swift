//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class SmithyXML.Reader

/// Defines a closure that can be used to convert a HTTP response to a Swift `Error`.
public typealias HTTPResponseErrorClosure = (HttpResponse) async throws -> Error

/// Defines a closure that can be used to convert a HTTP response and `Reader` for that response to a Swift `Error`.
public typealias HTTPResponseErrorBinding<Reader> = (HttpResponse, HTTPResponseDocumentBinding<Reader>) async throws -> Error

/// Provides a `HTTPResponseErrorClosure` for types that have Swift Decodable-based deserialization.
/// - Parameters:
///   - errorBinding: The `HttpResponseErrorBinding`-conforming type for this operation.
///   - decoder: The Swift `Decoder` to be used with the response.
/// - Returns: The `HTTPResponseErrorClosure` for deserializing this error.
public func responseErrorClosure<OperationErrorBinding: HttpResponseErrorBinding, Decoder: ResponseDecoder>(
    _ errorBinding: OperationErrorBinding.Type,
    decoder: Decoder
) -> HTTPResponseErrorClosure {
    return { response in
        try await OperationErrorBinding.makeError(httpResponse: response, decoder: decoder)
    }
}

/// Provides a `HTTPResponseErrorClosure` for types that have closure-based deserialization.
/// - Parameters:
///   - responseErrorBinding: The `HTTPResponseErrorBinding` closure for this operation.
///   - responseDocumentBinding: The `HTTPResponseDocumentBinding` closure for converting the HTTP response into a `Reader`.
/// - Returns: The `HTTPResponseErrorClosure` for deserializing this error.
public func responseErrorClosure<Reader>(
    _ responseErrorBinding: @escaping HTTPResponseErrorBinding<Reader>,
    _ responseDocumentBinding: @escaping HTTPResponseDocumentBinding<Reader>
) -> HTTPResponseErrorClosure {
    return { response in
        try await responseErrorBinding(response, responseDocumentBinding)
    }
}
