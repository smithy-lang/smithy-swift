//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import protocol SmithyAPI.RequestMessageSerializer
import class SmithyAPI.OperationContext
import struct Foundation.Data
import protocol SmithyReadWrite.SmithyWriter
import typealias SmithyReadWrite.WritingClosure
import SmithyHTTPAPI
import SmithyStreamsAPI

public struct PayloadBodyMiddleware<OperationStackInput,
                                    OperationStackOutput,
                                    OperationStackInputPayload,
                                    Writer: SmithyWriter>: Middleware {
    public let id: Swift.String = "PayloadBodyMiddleware"

    let rootNodeInfo: Writer.NodeInfo
    let inputWritingClosure: WritingClosure<OperationStackInputPayload, Writer>
    let keyPath: KeyPath<OperationStackInput, OperationStackInputPayload?>
    let defaultBody: String?

    public init(
        rootNodeInfo: Writer.NodeInfo,
        inputWritingClosure: @escaping WritingClosure<OperationStackInputPayload, Writer>,
        keyPath: KeyPath<OperationStackInput, OperationStackInputPayload?>,
        defaultBody: String?
    ) {
        self.rootNodeInfo = rootNodeInfo
        self.inputWritingClosure = inputWritingClosure
        self.keyPath = keyPath
        self.defaultBody = defaultBody
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

extension PayloadBodyMiddleware: RequestMessageSerializer {
    public typealias InputType = OperationStackInput
    public typealias RequestType = SdkHttpRequest
    public typealias AttributesType = OperationContext

    public func apply(input: OperationStackInput, builder: SdkHttpRequestBuilder, attributes: OperationContext) throws {
        do {
            if let payload = input[keyPath: keyPath] {
                let data = try Writer.write(
                    payload,
                    rootNodeInfo: rootNodeInfo,
                    with: inputWritingClosure
                )
                let body = ByteStream.data(data)
                builder.withBody(body)
            } else if let defaultBody {
                builder.withBody(.data(Data(defaultBody.utf8)))
            }
        } catch {
            throw ClientError.serializationFailed(error.localizedDescription)
        }
    }
}
