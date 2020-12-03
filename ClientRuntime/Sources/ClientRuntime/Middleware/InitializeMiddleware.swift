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

public struct InitializeMiddleware: Middleware {
    public var id: Int
    //key is the id of the middleware and value is the position
    var ids: [String: Position]

    
    public func handleMiddleware<Input, Output, OutputError>(to context: Context<Output, OutputError>, input: Input, next: Responder) -> Future<Void> where Input : HttpRequestBinding, Output : HttpResponseBinding, OutputError : HttpResponseBinding {
                //prepares input
                //adds idempotency token provider
                //sets any default params
                //presigned URLS
                return Future<Void>()
    }
}
