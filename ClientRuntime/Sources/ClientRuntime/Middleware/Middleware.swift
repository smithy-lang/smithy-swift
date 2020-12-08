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

public typealias HandleInitialize = (_ context: ExecutionContext, _ input: Any) -> (Any, Error?)
public protocol Middleware {
    //unique id for the middleware
    var id: String {get set}
   
    var middleware: HandleInitialize { get set }
    
    func run(context: ExecutionContext, input: Any, next: HandleInitialize) -> (Any, Error?)
}
