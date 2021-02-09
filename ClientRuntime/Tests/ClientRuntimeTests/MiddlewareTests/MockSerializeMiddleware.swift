// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

@testable import ClientRuntime

struct MockSerializeMiddleware: Middleware {
    typealias Context = HttpContext
    typealias MOutput = SdkHttpRequestBuilder
    
    let id: String
    let headerName: String
    let headerValue: String
    init(id: String, headerName: String, headerValue: String) {
        self.id = id
        self.headerName = headerName
        self.headerValue = headerValue
    }
    
    func handle<H>(context: HttpContext, input: MInput, next: H) -> Result<MOutput, Error> where H: Handler, Self.MInput == H.Input, Self.MOutput == H.Output, Self.Context == H.Context {
        
        let path = context.getPath()
        let method = context.getMethod()
        let host = "httpbin.org"
        input.withHost(host)
            .withHeader(name: "Content-type", value: "application/json")
            .withHeader(name: headerName, value: headerValue)
            .withHeader(name: "Host", value: host)
            .withPath(path)
            .withMethod(method)
        
        return next.handle(context: context, input: input)
    }
    
    typealias MInput = SdkHttpRequestBuilder
}
