//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import typealias SmithyReadWrite.DocumentWritingClosure
import typealias SmithyReadWrite.WritingClosure

public struct BodyMiddleware<OperationStackInput,
                             OperationStackOutput,
                             Writer>: Middleware {
    public let id: Swift.String = "BodyMiddleware"

    let documentWritingClosure: DocumentWritingClosure<OperationStackInput, Writer>
    let inputWritingClosure: WritingClosure<OperationStackInput, Writer>

    public init(
        documentWritingClosure: @escaping DocumentWritingClosure<OperationStackInput, Writer>,
        inputWritingClosure: @escaping WritingClosure<OperationStackInput, Writer>
    ) {
        self.documentWritingClosure = documentWritingClosure
        self.inputWritingClosure = inputWritingClosure
    }

    public func handle<H>(context: Context,
                          input: SerializeStepInput<OperationStackInput>,
                          next: H) async throws -> OperationOutput<OperationStackOutput>
    where H: Handler,
          Self.MInput == H.Input,
          Self.MOutput == H.Output,
          Self.Context == H.Context {
              do {
                  let data = try documentWritingClosure(input.operationInput, inputWritingClosure)
                  let body = HttpBody.data(data)
                  input.builder.withBody(body)
              } catch {
                  throw ClientError.serializationFailed(error.localizedDescription)
              }
              return try await next.handle(context: context, input: input)
          }

    public typealias MInput = SerializeStepInput<OperationStackInput>
    public typealias MOutput = OperationOutput<OperationStackOutput>
    public typealias Context = HttpContext
}
