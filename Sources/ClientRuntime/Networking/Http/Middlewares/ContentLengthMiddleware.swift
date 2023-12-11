// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

public struct ContentLengthMiddleware<OperationStackOutput>: Middleware {
    public let id: String = "ContentLength"

    private let contentLengthHeaderName = "Content-Length"

    private var requiresLength: Bool?

    private var unsignedPayload: Bool?

    /// Creates a new `ContentLengthMiddleware` with the supplied parameters
    /// - Parameters:
    ///   - requiresLength: Trait requires the length of a blob stream to be known. 
    ///     When the request body is not a streaming blob, `nil` should be passed. Defaults to `nil`.
    ///   - unsignedPayload: Trait signifies that the length of a stream in payload does not need to be known.
    ///     When the request body is not a streaming blob, `nil` should be passed. Defaults to `nil`.
    public init(requiresLength: Bool? = nil, unsignedPayload: Bool? = nil) {
        self.requiresLength = requiresLength
        self.unsignedPayload = unsignedPayload
    }

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
            } else if (requiresLength == false && unsignedPayload == true) ||
                        (requiresLength == nil && unsignedPayload == nil) {
                // Transfer-Encoding can be sent on all Event Streams where length cannot be determined
                // or on blob Data Streams where requiresLength is true and unsignedPayload is false
                // Only for HTTP/1.1 requests, will be removed in all HTTP/2 requests
                input.headers.update(name: "Transfer-Encoding", value: "Chunked")
            } else {
                let operation = context.attributes.get(key: AttributeKey<String>(name: "Operation"))
                             ?? "Error getting operation name"
                let errorMessage = (unsignedPayload ?? false) ?
                    "Missing content-length for operation: \(operation)" :
                    "Missing content-length for SigV4 signing on operation: \(operation)"
                throw StreamError.notSupported(errorMessage)
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
