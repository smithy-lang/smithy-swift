//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SmithyXML

public typealias HTTPResponseErrorClosure = (HttpResponse) async throws -> Error
public typealias HTTPResponseErrorBinding<Reader> = (HttpResponse, Reader) async throws -> Error

public func responseErrorClosure<OperationErrorBinding: HttpResponseErrorBinding, Decoder: ResponseDecoder>(
    _ errorBinding: OperationErrorBinding.Type,
    decoder: Decoder
) -> HTTPResponseErrorClosure {
    return { response in
        try await OperationErrorBinding.makeError(httpResponse: response, decoder: decoder)
    }
}

public func responseErrorClosure<Reader>(
    _ responseErrorBinding: @escaping HTTPResponseErrorBinding<Reader>,
    _ responseDocumentBinding: @escaping HTTPResponseDocumentBinding<Reader>
) -> HTTPResponseErrorClosure {
    return { response in
        try await responseErrorBinding(response, responseDocumentBinding(response))
    }
}

public func responseDocumentBinding() -> HTTPResponseDocumentBinding<Reader> {
    return { response in
        let data = try await response.body.readData()
        response.body = .data(data)
        return try Reader.from(data: data ?? Data())
    }
}
