// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

import AwsCommonRuntimeKit

public struct ContentMD5Middleware<OperationStackOutput>: Middleware {
    public let id: String = "ContentMD5"

    private let contentMD5HeaderName = "Content-MD5"

    public init() {}

    public func handle<H>(context: Context,
                          input: MInput,
                          next: H) async throws -> MOutput
    where H: Handler,
    Self.MInput == H.Input,
    Self.MOutput == H.Output,
    Self.Context == H.Context {

        switch input.body {
        case .data(let data):
            guard
                let data = data,
                let bodyString = String(data: data, encoding: .utf8)
            else {
                return try await next.handle(context: context, input: input)
            }
            let base64Encoded = try bodyString.base64EncodedMD5()
            input.headers.update(name: "Content-MD5", value: base64Encoded)
        case .stream:
            guard let logger = context.getLogger() else {
                return try await next.handle(context: context, input: input)
            }
            logger.error("TODO: Content-MD5 to stream buffer/reader")
        default:
            guard let logger = context.getLogger() else {
                return try await next.handle(context: context, input: input)
            }
            logger.error("Unhandled case for Content-MD5")
        }

        return try await next.handle(context: context, input: input)
    }

    public typealias MInput = SdkHttpRequestBuilder
    public typealias MOutput = OperationOutput<OperationStackOutput>
    public typealias Context = HttpContext
}
