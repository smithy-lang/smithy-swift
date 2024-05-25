//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import protocol SmithyAPI.RequestMessageSerializer
import class SmithyAPI.OperationContext
import struct Foundation.Data
import SmithyHTTPAPI

public struct StringBodyMiddleware<OperationStackInput, OperationStackOutput>: Middleware {
    public let id: Swift.String = "\(OperationStackInput.self)StringBodyMiddleware"

    let keyPath: KeyPath<OperationStackInput, String?>

    public init(keyPath: KeyPath<OperationStackInput, String?>) {
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

extension StringBodyMiddleware: RequestMessageSerializer {
    public typealias InputType = OperationStackInput
    public typealias RequestType = SdkHttpRequest
    public typealias AttributesType = OperationContext

    public func apply(input: OperationStackInput, builder: SdkHttpRequestBuilder, attributes: OperationContext) throws {
        builder.withBody(.data(Data((input[keyPath: keyPath] ?? "").utf8)))
    }
}
