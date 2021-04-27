// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

public struct ContentLengthMiddleware<OperationStackOutput: HttpResponseBinding,
                                      OperationStackError: HttpResponseBinding>: Middleware {
    public let id: String = "ContentLength"
    
    private let contentLengthHeaderName = "Content-Length"
    
    public init() {}
    
    public func handle<H>(context: Context,
                          input: MInput,
                          next: H) -> Result<MOutput, Error>
    where H: Handler,
          Self.MInput == H.Input,
          Self.MOutput == H.Output,
          Self.Context == H.Context {
        
        let contentLength: Int64 = {
            switch input.body {
            case .data(let data):
                return Int64(data?.count ?? 0)
            case .streamSource(let stream):
                // TODO: implement dynamic streaming with transfer-encoded-chunk header
                return stream.unwrap().contentLength
            case .none, .streamSink:
                return 0
            }
        }()
        
        input.headers.update(name: "Content-Length", value: String(contentLength))
        
        return next.handle(context: context, input: input)
    }
    
    public typealias MInput = SdkHttpRequestBuilder
    public typealias MOutput = OperationOutput<OperationStackOutput, OperationStackError>
    public typealias Context = HttpContext
}
