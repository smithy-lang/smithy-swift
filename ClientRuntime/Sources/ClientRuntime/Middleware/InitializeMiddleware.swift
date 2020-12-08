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
    public func respond(to context: ExecutionContext, input: Any) -> (Any?, Error?) {
        
        do {
        let inputCasted = input as? HttpRequestBinding
        let input = try inputCasted?.buildHttpRequest(method: context.method,
                                                        path: context.path,
                                                        encoder: context.encoder)
            
            //adds idempotency token provider
            //sets any default params
            //presigned URLS
            if let input = input {
                return(input, nil)
            } else {
                return (nil, nil)
            }
        }
        catch let err {
            return(nil, err)
        }

    }
    
    
}

public struct InitializeStep: Middleware{

    public var id: String = "Initialize stack step"
    
    //provides the ordered grouping of initialize middleware to be invoked on a handler
    public let ids: OrderedGroup
    
    public func handleMiddleware(to context: ExecutionContext, input: Any, next: Responder) -> (Any?, Error?) {
        let order = ids.getOrder()
        var responder = next
        for index in (order.count-1)...0 {
            responder = order
        }
        let (output, outputError) = next.respond(to: context, input: input)
        return (output, outputError)
    }
}
