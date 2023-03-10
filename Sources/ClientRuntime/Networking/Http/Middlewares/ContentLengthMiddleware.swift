// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

public struct ContentLengthMiddleware<OperationStackOutput: HttpResponseBinding>: Middleware {
    public let id: String = "ContentLength"

    private let contentLengthHeaderName = "Content-Length"

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
            input.headers.update(name: "Content-Length", value: String(data?.count ?? 0))
        case .stream(let stream):
            if let length = stream.length {
                input.headers.update(name: "Content-Length", value: String(length))
            } else {
                input.headers.update(name: "Transfer-Encoded", value: "Chunked")
            }
        default:
            input.headers.update(name: "Content-Length", value: "0")
        }

        return try await next.handle(context: context, input: input)
    }

    public typealias MInput = SdkHttpRequestBuilder
    public typealias MOutput = OperationOutput<OperationStackOutput>
    public typealias Context = HttpContext
}
