//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public typealias HTTPResponseOutputClosure<OperationStackOutput> = (HttpResponse) async throws -> OperationStackOutput

public typealias HTTPResponseOutputBinding<OperationStackOutput, Reader> =
    (HttpResponse, HTTPResponseDocumentBinding<Reader>) async throws -> OperationStackOutput

/// Provides a response closure for a type that conforms to the `HttpResponseBinding` decoding protocol.
///
/// This allows for use of JSON and FormURL serialized types with closure-based deserialization.
/// - Parameter decoder: The decoder to be used for decoding the value.
/// - Returns: A `HTTPResponseOutputClosure` that can be used to decode a value of the specified type.
public func responseClosure<OperationStackOutput: HttpResponseBinding, Decoder: ResponseDecoder>(
    decoder: Decoder
) -> HTTPResponseOutputClosure<OperationStackOutput> {
    return { response in
        try await OperationStackOutput(httpResponse: response, decoder: decoder)
    }
}

/// Provides a response closure for a type that provides closures for its output bindings.
/// - Parameters:
///   - responseOutputBinding: The `HTTPResponseOutputBinding` for the model to be deserialized.
///   - responseDocumentBinding: A `HTTPResponseDocumentBinding` to convert the HTTP response to a `Reader`.
/// - Returns: a `HTTPResponseOutputClosure` that can be used to deserialize a value of the specified type.
public func responseClosure<OperationStackOutput, Reader>(
    _ responseOutputBinding: @escaping HTTPResponseOutputBinding<OperationStackOutput, Reader>,
    _ responseDocumentBinding: @escaping HTTPResponseDocumentBinding<Reader>
) -> HTTPResponseOutputClosure<OperationStackOutput> {
    return { response in
        try await responseOutputBinding(response, responseDocumentBinding)
    }
}
