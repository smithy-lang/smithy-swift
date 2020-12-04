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
import AwsCommonRuntimeKit

public struct InitializeResponder : Responder {
    public typealias Input = HttpRequestBinding
    
    public typealias Output = SdkHttpRequest
    
    public typealias OutputError = ClientError
    
    public func respond(to context: ExecutionContext,
                                                    input: Input) -> (Output, OutputError?) {
        //adds idempotency token provider
        //sets any default params
        //presigned URLS

        do {
        let input = try! input.buildHttpRequest(method: context.method,
                                                        path: context.path,
                                                        encoder: context.encoder)
        }

        return(input, nil)
    }
    
    
}

public struct InitializeMiddleware: Middleware {

    public typealias Responder = InitializeResponder
    
    public var id: Int
    //key is the id of the middleware and value is the position
    var ids: [String: Position]
    
    public func handleMiddleware(to context: ExecutionContext, next: InitializeResponder) -> Future<Void> {
        let input = InitializeResponder()
        next.respond(to: context, input: input)
    }
}
