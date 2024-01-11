// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

public struct MutateHeadersMiddleware<OperationStackOutput>: Middleware {

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
        if !additional.dictionary.isEmpty {
            input.withHeaders(additional)
        }

        if !overrides.dictionary.isEmpty {
            for header in overrides.headers {
                input.updateHeader(name: header.name, value: header.value)
            }
        }

        if !conditionallySet.dictionary.isEmpty {
            for header in conditionallySet.headers where !input.headers.exists(name: header.name) {
                input.headers.add(name: header.name, values: header.value)
            }
        }

        return try await next.handle(context: context, input: input)
    }

    public typealias MInput = SdkHttpRequestBuilder
    public typealias MOutput = OperationOutput<OperationStackOutput>
    public typealias Context = HttpContext
}
