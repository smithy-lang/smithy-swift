//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct SerializableBodyMiddleware<OperationStackInput,
                                         OperationStackOutput: HttpResponseBinding>: Middleware {
    public let id: Swift.String = "\(String(describing: OperationStackInput.self))BodyMiddleware"

    let serializer: (OperationStackInput) throws -> Data

    public init(serializer: @escaping (OperationStackInput) throws -> Data) {
        self.serializer = serializer
    }

    public func handle<H>(context: Context,
                          input: SerializeStepInput<OperationStackInput>,
                          next: H) async throws -> OperationOutput<OperationStackOutput>
    where H: Handler,
          Self.MInput == H.Input,
          Self.MOutput == H.Output,
          Self.Context == H.Context {
              do {
                  let data = try serializer(input.operationInput)
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
