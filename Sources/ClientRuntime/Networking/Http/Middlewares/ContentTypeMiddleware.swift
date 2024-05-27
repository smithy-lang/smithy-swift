// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

import class Smithy.Context
@_spi(SdkHttpRequestBuilder) import SmithyHTTPAPI

public struct ContentTypeMiddleware<OperationStackInput, OperationStackOutput>: Middleware {

    public let id: String = "ContentType"

    let contentType: String

    public init(contentType: String) {
        self.contentType = contentType
    }

    public func handle<H>(context: Context,
                          input: SerializeStepInput<OperationStackInput>,
                          next: H) async throws -> OperationOutput<OperationStackOutput>
    where H: Handler,
    Self.MInput == H.Input,
    Self.MOutput == H.Output {
        addHeaders(builder: input.builder)
        return try await next.handle(context: context, input: input)
    }

    private func addHeaders(builder: SdkHttpRequestBuilder) {
        if !builder.headers.exists(name: "Content-Type") {
            builder.withHeader(name: "Content-Type", value: contentType)
        }
    }

    public typealias MInput = SerializeStepInput<OperationStackInput>
    public typealias MOutput = OperationOutput<OperationStackOutput>
}

extension ContentTypeMiddleware: HttpInterceptor {
    public typealias InputType = OperationStackInput
    public typealias OutputType = OperationStackOutput

    public func modifyBeforeRetryLoop(
        context: some MutableRequest<InputType, RequestType, AttributesType>
    ) async throws {
        let builder = context.getRequest().toBuilder()
        addHeaders(builder: builder)
        context.updateRequest(updated: builder.build())
    }
}
