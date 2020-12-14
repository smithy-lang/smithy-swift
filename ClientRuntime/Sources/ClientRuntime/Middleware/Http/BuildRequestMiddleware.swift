//
// Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.
// A copy of the License is located at
//
// http://aws.amazon.com/apache2.0
//
// or in the "license" file accompanying this file. This file is distributed
// on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
// express or implied. See the License for the specific language governing
// permissions and limitations under the License.
//

public struct BuildRequestMiddleware<Input: HttpRequestBinding>: Middleware {
    public var id: String = "BuildRequest"
    
    let input: Input
    
    public init(input: Input) {
        self.input = input
    }
    
    public func handle<H>(context: HttpRequestContext, subject: SdkHttpRequest, next: H) -> Result<SdkHttpRequest, ClientError> where H : Handler, Self.TContext == H.TContext, Self.TError == H.TError, Self.TSubject == H.TSubject {
        let method = context.getMethod()
        let path = context.getPath()
        let encoder = context.getEncoder()
        do {
        let sdkRequest = try input.buildHttpRequest(method: method, path: path, encoder: encoder)
        return next.handle(context: context, subject: sdkRequest)
        }
        catch let err {
            //errors not handled
        }
        return next.handle(context: context, subject: subject)
    }
    
    public typealias TContext = HttpRequestContext
    
    public typealias TSubject = SdkHttpRequest
    
    public typealias TError = ClientError
}
