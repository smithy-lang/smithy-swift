//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import protocol Smithy.RequestMessageSerializer
import class SmithyHTTPAPI.SdkHttpRequest
import class SmithyHTTPAPI.SdkHttpRequestBuilder
import class Smithy.Context

public struct HeaderMiddleware<OperationStackInput, OperationStackOutput> {
    public let id: String = "\(String(describing: OperationStackInput.self))HeadersMiddleware"

    let headerProvider: HeaderProvider<OperationStackInput>

    public init(_ headerProvider: @escaping HeaderProvider<OperationStackInput>) {
        self.headerProvider = headerProvider
    }
}

extension HeaderMiddleware: RequestMessageSerializer {
    public typealias InputType = OperationStackInput
    public typealias RequestType = SdkHttpRequest

    public func apply(input: OperationStackInput, builder: SdkHttpRequestBuilder, attributes: Smithy.Context) throws {
        builder.withHeaders(headerProvider(input))
    }
}
