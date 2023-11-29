//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public typealias HTTPResponseClosure<T> = (HttpResponse) async throws -> T

public func responseClosure<T: HttpResponseBinding, Decoder: ResponseDecoder>(
    decoder: Decoder
) -> HTTPResponseClosure<T> {
    return { response in
        return try await T(httpResponse: response, decoder: decoder)
    }
}
