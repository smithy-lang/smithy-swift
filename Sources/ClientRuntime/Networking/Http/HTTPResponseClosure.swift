//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public typealias HTTPResponseClosure<OperationStackOutput> = (HttpResponse) async throws -> OperationStackOutput

public func responseClosure<OperationStackOutput: HttpResponseBinding, Decoder: ResponseDecoder>(
    decoder: Decoder
) -> HTTPResponseClosure<OperationStackOutput> {
    return { response in
        try await OperationStackOutput(httpResponse: response, decoder: decoder)
    }
}
