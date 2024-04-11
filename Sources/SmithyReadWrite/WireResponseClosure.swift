//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public typealias WireResponseOutputClosure<WireResponse, OperationStackOutput> =
    (WireResponse) async throws -> OperationStackOutput

public typealias WireResponseOutputBinding<
    WireResponse: WireDataProviding,
    OperationStackOutput,
    Reader: SmithyReader> =
        (WireResponse, WireResponseDocumentBinding<WireResponse, Reader>) async throws -> OperationStackOutput

/// Provides a response output closure for a type that provides closures for its output bindings.
/// - Parameters:
///   - responseOutputBinding: The `WireResponseOutputBinding` for the model to be deserialized.
///   - responseDocumentBinding: A `WireResponseDocumentBinding` to convert the wire response to a `Reader`.
/// - Returns: a `HTTPResponseOutputClosure` that can be used to deserialize a value of the specified type.
public func wireResponseOutputClosure<WireResponse, OperationStackOutput, Reader>(
    _ responseOutputBinding: @escaping WireResponseOutputBinding<WireResponse, OperationStackOutput, Reader>,
    _ responseDocumentBinding: @escaping WireResponseDocumentBinding<WireResponse, Reader>
) -> WireResponseOutputClosure<WireResponse, OperationStackOutput> {
    return { response in
        try await responseOutputBinding(response, responseDocumentBinding)
    }
}
