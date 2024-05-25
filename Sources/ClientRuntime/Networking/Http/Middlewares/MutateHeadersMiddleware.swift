// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

import class SmithyAPI.OperationContext
import struct SmithyHTTPAPI.Headers
@_spi(SdkHttpRequestBuilder) import SmithyHTTPAPI

public struct MutateHeadersMiddleware<OperationStackInput, OperationStackOutput>: Middleware {

    public let id: String = "MutateHeaders"

    private var overrides: Headers
    private var additional: Headers
    private var conditionallySet: Headers

    public init(overrides: [String: String]? = nil,
                additional: [String: String]? = nil,
                conditionallySet: [String: String]? = nil) {
        self.overrides = Headers(overrides ?? [:])
        self.additional = Headers(additional ?? [:])
        self.conditionallySet = Headers(conditionallySet ?? [:])
    }

    public func handle<H>(context: Context,
                          input: SdkHttpRequestBuilder,
                          next: H) async throws -> OperationOutput<OperationStackOutput>
    where H: Handler,
    Self.MInput == H.Input,
    Self.MOutput == H.Output,
    Self.Context == H.Context {
        mutateHeaders(builder: input)
        return try await next.handle(context: context, input: input)
    }

    private func mutateHeaders(builder: SdkHttpRequestBuilder) {
        if !additional.dictionary.isEmpty {
            builder.withHeaders(additional)
        }

        if !overrides.dictionary.isEmpty {
            for header in overrides.headers {
                builder.updateHeader(name: header.name, value: header.value)
            }
        }

        if !conditionallySet.dictionary.isEmpty {
            for header in conditionallySet.headers where !builder.headers.exists(name: header.name) {
                builder.headers.add(name: header.name, values: header.value)
            }
        }
    }

    public typealias MInput = SdkHttpRequestBuilder
    public typealias MOutput = OperationOutput<OperationStackOutput>
    public typealias Context = OperationContext
}

extension MutateHeadersMiddleware: HttpInterceptor {
    public typealias InputType = OperationStackInput
    public typealias OutputType = OperationStackOutput

    public func modifyBeforeTransmit(
        context: some MutableRequest<InputType, RequestType, AttributesType>
    ) async throws {
        let builder = context.getRequest().toBuilder()
        mutateHeaders(builder: builder)
        context.updateRequest(updated: builder.build())
    }
}
