// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

public struct ContentLengthMiddleware<StackInput>: Middleware where StackInput: Encodable, StackInput: Reflection {
    public let id: String = "ContentLength"
    
    public init() {}
    
    public func handle<H>(context: Context,
                          input: SerializeInput<StackInput>,
                          next: H) -> Result<SdkHttpRequestBuilder, Error>
    where H: Handler,
          Self.MInput == H.Input,
          Self.MOutput == H.Output,
          Self.Context == H.Context {
        switch input.builder.body {
        case .data(let data):
            if let contentLength = data?.count {
                input.builder.withHeader(name: "Content-Length", value: String(contentLength))
            }
        case .none, .streamSink(_):
            break
        case .streamSource(let sourceProvider):
            let contentLength = sourceProvider.unwrap().contentLength
            input.builder.withHeader(name: "Content-Length", value: String(contentLength))
        }
        
        return next.handle(context: context, input: input)
    }
    
    public typealias MInput = SerializeInput<StackInput>
    public typealias MOutput = SdkHttpRequestBuilder
    public typealias Context = HttpContext
}
