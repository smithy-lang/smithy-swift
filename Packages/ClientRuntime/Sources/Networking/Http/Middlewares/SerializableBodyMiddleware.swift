//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct SerializableBodyMiddleware<OperationStackInput: Encodable,
                                         OperationStackOutput: HttpResponseBinding>: Middleware {
    public let id: Swift.String = "\(String(describing: OperationStackInput.self))BodyMiddleware"
    
    public init() {}
    
    public func handle<H>(context: Context,
                          input: SerializeStepInput<OperationStackInput>,
                          next: H) async throws -> OperationOutput<OperationStackOutput>
    where H: Handler,
          Self.MInput == H.Input,
          Self.MOutput == H.Output,
          Self.Context == H.Context {
              do {
                  let encoder = context.getEncoder()
                  let data = try encoder.encode(input.operationInput)
                  let body = HttpBody.data(data)
                  input.builder.withBody(body)
              } catch let err {
                  throw ClientError.serializationFailed(err.localizedDescription)
              }
              return try await next.handle(context: context, input: input)
          }
    
    public typealias MInput = SerializeStepInput<OperationStackInput>
    public typealias MOutput = OperationOutput<OperationStackOutput>
    public typealias Context = HttpContext
}
