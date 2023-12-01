//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import typealias SmithyReadWrite.DocumentWritingClosure
import typealias SmithyReadWrite.WritingClosure

public struct EventStreamBodyMiddleware<OperationStackInput,
                                        OperationStackOutput,
                                        OperationStackInputPayload: MessageMarshallable>:
                                        Middleware {
    public let id: Swift.String = "EventStreamBodyMiddleware"

    let keyPath: KeyPath<OperationStackInput, AsyncThrowingStream<OperationStackInputPayload, Swift.Error>?>
    let defaultBody: String?

    public init(
        keyPath: KeyPath<OperationStackInput, AsyncThrowingStream<OperationStackInputPayload, Swift.Error>?>,
        defaultBody: String? = nil
    ) {
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
              let encoder = context.getEncoder()
              if let eventStream = input.operationInput[keyPath: keyPath] {
                  guard let messageEncoder = context.getMessageEncoder() else {
                      fatalError("Message encoder is required for streaming payload")
                  }
                  guard let messageSigner = context.getMessageSigner() else {
                      fatalError("Message signer is required for streaming payload")
                  }
                  let encoderStream = EventStream.DefaultMessageEncoderStream(
                    stream: eventStream,
                    messageEncoder: messageEncoder,
                    requestEncoder: encoder,
                    messageSigner: messageSigner
                  )
                  input.builder.withBody(.stream(encoderStream))
              } else if let defaultBody {
                  input.builder.withBody(HttpBody.data(Data(defaultBody.utf8)))
              }
              return try await next.handle(context: context, input: input)
          }

    public typealias MInput = SerializeStepInput<OperationStackInput>
    public typealias MOutput = OperationOutput<OperationStackOutput>
    public typealias Context = HttpContext
}
