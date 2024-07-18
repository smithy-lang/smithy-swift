//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Smithy
import SmithyHTTPAPI
import struct Foundation.Data
import protocol SmithyReadWrite.SmithyWriter
import typealias SmithyReadWrite.WritingClosure

public struct BodyMiddleware<OperationStackInput,
                             OperationStackOutput,
                             Writer: SmithyWriter>: Middleware {
    public let id: Swift.String = "BodyMiddleware"

    let rootNodeInfo: Writer.NodeInfo
    let inputWritingClosure: WritingClosure<OperationStackInput, Writer>

    public init(
        rootNodeInfo: Writer.NodeInfo,
        inputWritingClosure: @escaping WritingClosure<OperationStackInput, Writer>
    ) {
        self.rootNodeInfo = rootNodeInfo
        self.inputWritingClosure = inputWritingClosure
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

extension BodyMiddleware: RequestMessageSerializer {
    public typealias InputType = OperationStackInput
    public typealias RequestType = HTTPRequest
    public typealias AttributesType = Smithy.Context

    public func apply(input: OperationStackInput, builder: HTTPRequestBuilder, attributes: Smithy.Context) throws {
        do {
            let data = try Writer.write(
                input,
                rootNodeInfo: rootNodeInfo,
                with: inputWritingClosure
            )
            let body = ByteStream.data(data)
            builder.withBody(body)
        } catch {
            throw ClientError.serializationFailed(error.localizedDescription)
        }
    }
}
