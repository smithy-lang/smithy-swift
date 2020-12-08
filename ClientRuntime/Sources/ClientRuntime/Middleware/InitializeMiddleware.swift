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

//public struct InitializeHandler<Input> {
//   // public let next: InitializeHandler<Input>
//    public func respond(to context: ExecutionContext, input: Input) -> (SdkHttpRequest, Error?) {
//       // return next.respond(to: context, input: input)
//    }
//}

public struct InitializeMiddleware: Middleware {
    
    public var middleware: HandleInitialize
    
    public var id: String //unique id for the middleware, 2 of the same are not allowed
    
    public func run(context: ExecutionContext, input: Any, next: HandleInitialize) -> (Any, Error?) {
        let (output, error) = middleware(context, input)
        if let error = error {
            return (output, error) //stop the chain and return the error
        }
        return next(context, output) //otherwise call next on the chain
    }
}


public struct InitializeStep{

    public var id: String = "Initialize stack step"
    
    //provides the ordered grouping of initialize middleware to be invoked on a handler
    public var ids: OrderedGroup
    
    public func handleMiddleware(to context: ExecutionContext, input: Any, next: HandleInitialize) -> (SdkHttpRequest?, Error?) {
        let order = ids.items
        let firstMiddleware = order[0].value
        let (output, outputError) = firstMiddleware.run(context: context,input: input,next: next)
        return (output as? SdkHttpRequest, outputError)
    }
    
    public mutating func add(middleware: InitializeMiddleware, position: Position) {
        ids.add(middleware: middleware, position: position)
    }
}
