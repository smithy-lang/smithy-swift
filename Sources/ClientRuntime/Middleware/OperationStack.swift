// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

public struct OperationStack<OperationStackInput, OperationStackOutput> {

    /// returns the unique id for the operation stack as middleware
    public var id: String
    public var initializeStep: InitializeStep<OperationStackInput, OperationStackOutput>
    public var serializeStep: SerializeStep<OperationStackInput, OperationStackOutput>
    public var buildStep: BuildStep<OperationStackOutput>
    public var finalizeStep: FinalizeStep<OperationStackOutput>
    public var deserializeStep: DeserializeStep<OperationStackOutput>

    public init(id: String) {
        self.id = id
        self.initializeStep = InitializeStep<OperationStackInput, OperationStackOutput>(id: InitializeStepId)
        self.serializeStep = SerializeStep<OperationStackInput, OperationStackOutput>(id: SerializeStepId)
        self.buildStep = BuildStep<OperationStackOutput>(id: BuildStepId)
        self.finalizeStep = FinalizeStep<OperationStackOutput>(id: FinalizeStepId)
        self.deserializeStep = DeserializeStep<OperationStackOutput>(id: DeserializeStepId)
    }

    /// This execute will execute the stack and use your next as the last closure in the chain
    public func handleMiddleware<H: Handler>(context: HttpContext,
                                             input: OperationStackInput,
                                             next: H) async throws -> OperationStackOutput
    where H.Input == SdkHttpRequest,
          H.Output == OperationOutput<OperationStackOutput>,
          H.Context == HttpContext {

              let deserialize = compose(next: DeserializeStepHandler(handler: next), with: deserializeStep)
              let finalize = compose(next: FinalizeStepHandler(handler: deserialize), with: finalizeStep)
              let build = compose(next: BuildStepHandler(handler: finalize), with: buildStep)
              let serialize = compose(next: SerializeStepHandler(handler: build), with: serializeStep)
              let initialize = compose(next: InitializeStepHandler(handler: serialize), with: initializeStep)

              let result = try await initialize.handle(context: context, input: input)
              guard let output = result.output else {
                  let errorMessage = [
                    "Something went terribly wrong where the output was not set on the response.",
                    "Please open a ticket with us at https://github.com/awslabs/aws-sdk-swift"
                  ].joined(separator: " ")
                  throw ClientError.unknownError(errorMessage)
              }
              return output
          }

    mutating public func presignedRequest<H: Handler>(
        context: HttpContext,
        input: OperationStackInput,
        next: H
    ) async throws -> SdkHttpRequestBuilder? where
    H.Input == SdkHttpRequest,
    H.Output == OperationOutput<OperationStackOutput>,
    H.Context == HttpContext {
        var builder: SdkHttpRequestBuilder?
        self.finalizeStep.intercept(
            position: .after,
            middleware: PresignerShim<OperationStackOutput>(handler: { buildInMiddleware in
                builder = buildInMiddleware
            }))
        _ = try await handleMiddleware(context: context, input: input, next: next)
        return builder
    }

    /// Compose (wrap) the handler with the given middleware or essentially build out the linked list of middleware
    private func compose<H: Handler, M: Middleware>(next handler: H,
                                                    with middlewares: M...) -> AnyHandler<H.Input,
                                                                                          H.Output,
                                                                                          H.Context>
    where M.MOutput == H.Output,
          M.MInput == H.Input,
          H.Context == M.Context {
        guard !middlewares.isEmpty,
              let lastMiddleware = middlewares.last else {
            return handler.eraseToAnyHandler()
        }

        let numberOfMiddlewares = middlewares.count
        var composedHandler = ComposedHandler(handler, lastMiddleware)

        guard numberOfMiddlewares > 1 else {
            return composedHandler.eraseToAnyHandler()
        }
        let reversedCollection = (0...(numberOfMiddlewares - 2)).reversed()
        for index in reversedCollection {
            composedHandler = ComposedHandler(composedHandler, middlewares[index])
        }

        return composedHandler.eraseToAnyHandler()
    }
}
