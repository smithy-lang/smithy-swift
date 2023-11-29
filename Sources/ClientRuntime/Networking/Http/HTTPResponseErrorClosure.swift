//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public typealias HTTPResponseErrorClosure = (HttpResponse) async throws -> Error

public func responseErrorClosure<E: HttpResponseErrorBinding, Decoder: ResponseDecoder>(_ errorBinding: E.Type, decoder: Decoder) -> HTTPResponseErrorClosure {
    return { response in
        return try await E.makeError(httpResponse: response, decoder: decoder)
    }
}
