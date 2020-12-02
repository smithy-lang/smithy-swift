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

public struct MiddlewareStack<Output: HttpResponseBinding, OutputError: HttpResponseBinding> {
    let context: Context<Output, OutputError>
    	
    public var initializeMiddleware: [Middleware]
    public var serializeMiddleware: [Middleware]
    public var buildMiddleware: [Middleware]
    public var finalizeMiddleware: [Middleware]
    public var deserializeMiddleware: [Middleware]
    
    func handleMiddleware(context: Context<Output, OutputError>,
                          client: SdkHttpClient,
                          completion: @escaping (SdkResult<Output, OutputError>) -> Void) {
        var futures = [Future<Void>]()
        for middleware in initializeMiddleware {
            futures.append(middleware.respond(to: context))
        }
        
        
        client.execute(context: context, completion: completion)
        
    }
}
