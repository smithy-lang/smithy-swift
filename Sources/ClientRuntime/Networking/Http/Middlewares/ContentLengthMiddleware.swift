// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

import struct Smithy.AttributeKey
import class Smithy.Context
import enum Smithy.StreamError
import SmithyHTTPAPI

public struct ContentLengthMiddleware<OperationStackInput, OperationStackOutput>: Middleware {
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
    Self.MOutput == H.Output {
        try addHeaders(builder: input, attributes: context)
        return try await next.handle(context: context, input: input)
    }

    private func addHeaders(builder: SdkHttpRequestBuilder, attributes: Context) throws {
        switch builder.body {
        case .data(let data):
            let contentLength = data?.count ?? 0
            builder.updateHeader(name: "Content-Length", value: String(contentLength))
        case .stream(let stream):
            if let length = stream.length {
                if !stream.isEligibleForChunkedStreaming
                    && !(builder.headers.value(for: "Transfer-Encoding") == "chunked") {
                    builder.updateHeader(name: "Content-Length", value: String(length))
                }
            } else if (requiresLength == false && unsignedPayload == true) ||
                        (requiresLength == nil && unsignedPayload == nil) {
                // Transfer-Encoding can be sent on all Event Streams where length cannot be determined
                // or on blob Data Streams where requiresLength is true and unsignedPayload is false
                // Only for HTTP/1.1 requests, will be removed in all HTTP/2 requests
                builder.updateHeader(name: "Transfer-Encoding", value: "chunked")
            } else {
                let operation = attributes.getOperation()
                             ?? "Error getting operation name"
                let errorMessage = (unsignedPayload ?? false) ?
                    "Missing content-length for operation: \(operation)" :
                    "Missing content-length for SigV4 signing on operation: \(operation)"
                throw StreamError.notSupported(errorMessage)
            }
        case .noStream:
            builder.updateHeader(name: "Content-Length", value: "0")
        }
    }

    public typealias MInput = SdkHttpRequestBuilder
    public typealias MOutput = OperationOutput<OperationStackOutput>
}

extension ContentLengthMiddleware: HttpInterceptor {
    public typealias InputType = OperationStackInput
    public typealias OutputType = OperationStackOutput

    public func modifyBeforeTransmit(
        context: some MutableRequest<InputType, RequestType>
    ) async throws {
        let builder = context.getRequest().toBuilder()
        try addHeaders(builder: builder, attributes: context.getAttributes())
        context.updateRequest(updated: builder.build())
    }
}
