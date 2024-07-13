// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

import class Smithy.Context
import SmithyHTTPAPI

public struct ContentTypeMiddleware<OperationStackInput, OperationStackOutput> {

    public let id: String = "ContentType"

    let contentType: String

    public init(contentType: String) {
        self.contentType = contentType
    }

    private func addHeaders(builder: SdkHttpRequestBuilder) {
        if !builder.headers.exists(name: "Content-Type") {
            builder.withHeader(name: "Content-Type", value: contentType)
        }
    }
}

extension ContentTypeMiddleware: HttpInterceptor {
    public typealias InputType = OperationStackInput
    public typealias OutputType = OperationStackOutput

    public func modifyBeforeRetryLoop(
        context: some MutableRequest<InputType, RequestType>
    ) async throws {
        let builder = context.getRequest().toBuilder()
        addHeaders(builder: builder)
        context.updateRequest(updated: builder.build())
    }
}
