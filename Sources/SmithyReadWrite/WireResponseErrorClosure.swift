//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Defines a closure that can be used to convert a HTTP response to a Swift `Error`.
public typealias WireResponseErrorClosure<WireResponse> = (WireResponse) async throws -> Error

/// Defines a closure that can be used to convert a HTTP response and `Reader` for that response to a Swift `Error`.
public typealias WireResponseErrorBinding<WireResponse: WireDataProviding, Reader: SmithyReader> =
    (WireResponse, WireResponseDocumentBinding<WireResponse, Reader>) async throws -> Error

/// Provides a `WireResponseErrorClosure` for types that have closure-based deserialization.
/// - Parameters:
///   - responseErrorBinding: The `WireResponseErrorBinding` closure for this operation.
///   - responseDocumentBinding: The `WireResponseDocumentBinding` closure for converting the HTTP response into a `Reader`.
/// - Returns: The `WireResponseErrorClosure` for deserializing this error.
public func wireResponseErrorClosure<WireResponse, Reader>(
    _ responseErrorBinding: @escaping WireResponseErrorBinding<WireResponse, Reader>,
    _ responseDocumentBinding: @escaping WireResponseDocumentBinding<WireResponse, Reader>
) -> WireResponseErrorClosure<WireResponse> {
    return { response in
        try await responseErrorBinding(response, responseDocumentBinding)
    }
}
