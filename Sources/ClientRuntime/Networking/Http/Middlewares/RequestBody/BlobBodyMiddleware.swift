//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import protocol Smithy.RequestMessageSerializer
import class Smithy.Context
import class SmithyHTTPAPI.SdkHttpRequest
import class SmithyHTTPAPI.SdkHttpRequestBuilder
import struct Foundation.Data

public struct BlobBodyMiddleware<OperationStackInput,
                                    OperationStackOutput>: Middleware {
    public let id: Swift.String = "BlobBodyMiddleware"

    let keyPath: KeyPath<OperationStackInput, Data?>

    public init(keyPath: KeyPath<OperationStackInput, Data?>) {
        self.keyPath = keyPath
    }

    public func handle<H>(context: Smithy.Context,
                          input: SerializeStepInput<OperationStackInput>,
                          next: H) async throws -> OperationOutput<OperationStackOutput>
    where H: Handler,
          Self.MInput == H.Input,
          Self.MOutput == H.Output {
              try apply(input: input.operationInput, builder: input.builder, attributes: context)
              return try await next.handle(context: context, input: input)
          }

    public typealias MInput = SerializeStepInput<OperationStackInput>
    public typealias MOutput = OperationOutput<OperationStackOutput>
    public typealias Context = Smithy.Context
}

extension BlobBodyMiddleware: RequestMessageSerializer {
    public typealias InputType = OperationStackInput
    public typealias RequestType = SdkHttpRequest
    public typealias AttributesType = Smithy.Context

    public func apply(input: OperationStackInput, builder: SdkHttpRequestBuilder, attributes: Smithy.Context) throws {
        builder.withBody(.data(input[keyPath: keyPath]))
    }
}
