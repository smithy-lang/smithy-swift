//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class Smithy.Context
import struct Foundation.Data
import Smithy
import SmithyHTTPAPI

public struct EnumBodyMiddleware<OperationStackInput,
                                 OperationStackOutput,
                                 Primitive: RawRepresentable>: Middleware where Primitive.RawValue == String {
    public let id: Swift.String = "EnumBodyMiddleware"

    let keyPath: KeyPath<OperationStackInput, Primitive?>

    public init(keyPath: KeyPath<OperationStackInput, Primitive?>) {
        self.keyPath = keyPath
    }

    public func handle<H>(context: Context,
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

extension EnumBodyMiddleware: RequestMessageSerializer {
    public typealias InputType = OperationStackInput
    public typealias RequestType = SdkHttpRequest
    public typealias AttributesType = Smithy.Context

    public func apply(input: OperationStackInput, builder: SdkHttpRequestBuilder, attributes: Smithy.Context) throws {
        let bodyString = input[keyPath: keyPath]?.rawValue ?? ""
        let bodyData = Data(bodyString.utf8)
        builder.withBody(.data(bodyData))
    }
}
