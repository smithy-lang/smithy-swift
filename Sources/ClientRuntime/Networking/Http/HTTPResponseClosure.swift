//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public typealias HTTPResponseClosure<OperationStackOutput> = (HttpResponse) async throws -> OperationStackOutput

public typealias HTTPResponseOutputBinding<OperationStackOutput, Reader> =
    (HttpResponse, Reader) async throws -> OperationStackOutput

/// Provides a response closure for a type that conforms to `HttpResponseBinding`.
///
/// This allows for use of JSON and FormURL serialized types with closure-based deserialization.
/// - Parameter decoder: The decoder to be used for decoding the value.
/// - Returns: A `HTTPResponseClosure` that can be used to decode a value of the specified type.
public func responseClosure<OperationStackOutput: HttpResponseBinding, Decoder: ResponseDecoder>(
    decoder: Decoder
) -> HTTPResponseClosure<OperationStackOutput> {
    return { response in
        try await OperationStackOutput(httpResponse: response, decoder: decoder)
    }
}

/// Provides a response closure for a type that provides closures for its output bindings.
/// - Parameters:
///   - responseOutputBinding: The `HTTPResponseOutputBinding` for the model to be deserialized.
///   - responseDocumentBinding: A `HTTPResponseDocumentBinding` to convert the HTTP response to a `Reader`.
/// - Returns: a `HTTPResponseClosure` that can be used to deserialize a value of the specified type.
public func responseClosure<OperationStackOutput, Reader>(
    _ responseOutputBinding: @escaping HTTPResponseOutputBinding<OperationStackOutput, Reader>,
    _ responseDocumentBinding: @escaping HTTPResponseDocumentBinding<Reader>
) -> HTTPResponseClosure<OperationStackOutput> {
    return { response in
        try await responseOutputBinding(response, responseDocumentBinding(response))
    }
}
