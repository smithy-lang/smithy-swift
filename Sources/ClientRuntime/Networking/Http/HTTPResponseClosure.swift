//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public typealias HTTPResponseClosure<OperationStackOutput> = 
    (HttpResponse) async throws -> OperationStackOutput
public typealias HTTPResponseOutputBinding<OperationStackOutput, Reader> = 
    (HttpResponse, Reader) async throws -> OperationStackOutput
public typealias HTTPResponseDocumentBinding<Reader> =
    (HttpResponse) async throws -> Reader

public func responseClosure<OperationStackOutput: HttpResponseBinding, Decoder: ResponseDecoder>(
    decoder: Decoder
) -> HTTPResponseClosure<OperationStackOutput> {
    return { response in
        try await OperationStackOutput(httpResponse: response, decoder: decoder)
    }
}

public func responseClosure<OperationStackOutput, Reader>(
    _ responseOutputBinding: @escaping HTTPResponseOutputBinding<OperationStackOutput, Reader>,
    _ responseDocumentBinding: @escaping HTTPResponseDocumentBinding<Reader>
) -> HTTPResponseClosure<OperationStackOutput> {
    return { response in
        try await responseOutputBinding(response, responseDocumentBinding(response))
    }
}
