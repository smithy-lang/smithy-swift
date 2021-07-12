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
        
        let contentLength: Int64 = {
            switch input.body {
            case .data(let data):
                return Int64(data?.count ?? 0)
            case .stream(let stream):
                // TODO: implement dynamic streaming with transfer-encoded-chunk header
                return stream.toBytes().length
            case .none:
                return 0
            }
        }()
        
        input.headers.update(name: "Content-Length", value: String(contentLength))
        
        return next.handle(context: context, input: input)
    }
    
    public typealias MInput = SdkHttpRequestBuilder
    public typealias MOutput = OperationOutput<OperationStackOutput>
    public typealias Context = HttpContext
    public typealias MError = SdkError<OperationStackError>
}
