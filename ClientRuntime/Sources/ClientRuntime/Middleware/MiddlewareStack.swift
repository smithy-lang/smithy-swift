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

public struct MiddlewareStack {
    
    public var initializeMiddleware: InitializeMiddleware
    public var serializeMiddleware: SerializeMiddleware
    public var buildMiddleware: BuildMiddleware
    public var finalizeMiddleware: FinalizeMiddleware
    public var deserializeMiddleware: DeserializeMiddleware
    
    public init(initializeMiddleware: InitializeMiddleware,
                serializeMiddleware: SerializeMiddleware,
                buildMiddleware: BuildMiddleware,
                finalizeMiddleware: FinalizeMiddleware,
                deserializeMiddleware: DeserializeMiddleware) {
        self.initializeMiddleware = initializeMiddleware
        self.serializeMiddleware = serializeMiddleware
        self.buildMiddleware = buildMiddleware
        self.finalizeMiddleware = finalizeMiddleware
        self.deserializeMiddleware = deserializeMiddleware
    }
}
