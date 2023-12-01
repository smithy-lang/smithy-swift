//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import typealias SmithyReadWrite.DocumentWritingClosure
import typealias SmithyReadWrite.WritingClosure

public struct PayloadBodyMiddleware<OperationStackInput,
                                    OperationStackOutput,
                                    OperationStackInputPayload,
                                    Writer>: Middleware {
    public let id: Swift.String = "PayloadBodyMiddleware"

    let documentWritingClosure: DocumentWritingClosure<OperationStackInputPayload, Writer>
    let inputWritingClosure: WritingClosure<OperationStackInputPayload, Writer>
    let keyPath: KeyPath<OperationStackInput, OperationStackInputPayload?>
    let defaultBody: String?

    public init(
        documentWritingClosure: @escaping DocumentWritingClosure<OperationStackInputPayload, Writer>,
        inputWritingClosure: @escaping WritingClosure<OperationStackInputPayload, Writer>,
        keyPath: KeyPath<OperationStackInput, OperationStackInputPayload?>,
        defaultBody: String?
    ) {
        self.documentWritingClosure = documentWritingClosure
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
              do {
                  if let payload = input.operationInput[keyPath: keyPath] {
                      let data = try documentWritingClosure(payload, inputWritingClosure)
                      let body = HttpBody.data(data)
                      input.builder.withBody(body)
                  } else if let defaultBody {
                      input.builder.withBody(HttpBody.data(Data(defaultBody.utf8)))
                  }
              } catch {
                  throw ClientError.serializationFailed(error.localizedDescription)
              }
              return try await next.handle(context: context, input: input)
          }

    public typealias MInput = SerializeStepInput<OperationStackInput>
    public typealias MOutput = OperationOutput<OperationStackOutput>
    public typealias Context = HttpContext
}
