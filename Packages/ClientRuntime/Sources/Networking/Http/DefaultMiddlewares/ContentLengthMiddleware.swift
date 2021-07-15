// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

public struct ContentLengthMiddleware<OperationStackOutput: HttpResponseBinding,
                                      OperationStackError: HttpResponseBinding>: Middleware {
    public let id: String = "ContentLength"
    
    private let contentLengthHeaderName = "Content-Length"
    
    public init() {}
    
    public func handle<H>(context: Context,
                          input: MInput,
                          next: H) -> Result<MOutput, MError>
    where H: Handler,
    Self.MInput == H.Input,
    Self.MOutput == H.Output,
    Self.Context == H.Context,
    Self.MError == H.MiddlewareError {
        
        
        switch input.body {
        case .data(let data):
            input.headers.update(name: "Content-Length", value: String(data?.count ?? 0))
        case .stream(let stream):
            switch stream {
            case .buffer(let bytes):
                input.headers.update(name: "Content-Length", value: String(bytes.length))
            case .reader(_):
                input.headers.update(name: "Transfer-Encoded", value: "Chunked")
            }
        default:
            input.headers.update(name: "Content-Length", value: "0")
        }
        
        
        return next.handle(context: context, input: input)
    }
    
    public typealias MInput = SdkHttpRequestBuilder
    public typealias MOutput = OperationOutput<OperationStackOutput>
    public typealias Context = HttpContext
    public typealias MError = SdkError<OperationStackError>
}
