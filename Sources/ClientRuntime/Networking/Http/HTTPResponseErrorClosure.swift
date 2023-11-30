//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public typealias HTTPResponseErrorClosure = (HttpResponse) async throws -> Error

public func responseErrorClosure<OperationErrorBinding: HttpResponseErrorBinding, Decoder: ResponseDecoder>(
    _ errorBinding: OperationErrorBinding.Type,
    decoder: Decoder
) -> HTTPResponseErrorClosure {
    return { response in
        try await OperationErrorBinding.makeError(httpResponse: response, decoder: decoder)
    }
}
