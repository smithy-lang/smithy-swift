// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

public struct ContentLengthMiddleware<OperationStackInput: Encodable & Reflection,
                                      OperationStackOutput>: Middleware {
    public let id: String = "ContentLength"
    
    public init() {}
    
    public func handle<H>(context: Context,
                          input: MInput,
                          next: H) -> Result<MOutput, Error>
    where H: Handler,
          Self.MInput == H.Input,
          Self.MOutput == H.Output,
          Self.Context == H.Context {
        switch input.body {
        case .data(let data):
            if let contentLength = data?.count {
                input.withHeader(name: "Content-Length", value: String(contentLength))
            }
        case .none, .streamSink:
            break
        case .streamSource(let sourceProvider):
            let contentLength = sourceProvider.unwrap().contentLength
            input.withHeader(name: "Content-Length", value: String(contentLength))
        }
        
        return next.handle(context: context, input: input)
    }
    
    public typealias MInput = SdkHttpRequestBuilder
    public typealias MOutput = OperationStackOutput
    public typealias Context = HttpContext
}
