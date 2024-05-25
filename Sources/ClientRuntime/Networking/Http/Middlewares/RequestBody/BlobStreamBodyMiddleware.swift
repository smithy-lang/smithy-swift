//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import protocol SmithyAPI.RequestMessageSerializer
import class SmithyAPI.OperationContext
import enum SmithyStreamsAPI.ByteStream
import class SmithyHTTPAPI.SdkHttpRequest
import class SmithyHTTPAPI.SdkHttpRequestBuilder
import struct Foundation.Data

public struct BlobStreamBodyMiddleware<OperationStackInput,
                                    OperationStackOutput>: Middleware {
    public let id: Swift.String = "BlobStreamBodyMiddleware"

    let keyPath: KeyPath<OperationStackInput, ByteStream?>

    public init(keyPath: KeyPath<OperationStackInput, ByteStream?>) {
        self.keyPath = keyPath
    }

    public func handle<H>(context: Context,
                          input: SerializeStepInput<OperationStackInput>,
                          next: H) async throws -> OperationOutput<OperationStackOutput>
    where H: Handler,
          Self.MInput == H.Input,
          Self.MOutput == H.Output,
          Self.Context == H.Context {
              try apply(input: input.operationInput, builder: input.builder, attributes: context)
              return try await next.handle(context: context, input: input)
          }

    public typealias MInput = SerializeStepInput<OperationStackInput>
    public typealias MOutput = OperationOutput<OperationStackOutput>
    public typealias Context = OperationContext
}

extension BlobStreamBodyMiddleware: RequestMessageSerializer {
    public typealias InputType = OperationStackInput
    public typealias RequestType = SdkHttpRequest
    public typealias AttributesType = OperationContext

    public func apply(input: OperationStackInput, builder: SdkHttpRequestBuilder, attributes: OperationContext) throws {
        if let byteStream = input[keyPath: keyPath] {
            builder.withBody(byteStream)
        }
    }
}
