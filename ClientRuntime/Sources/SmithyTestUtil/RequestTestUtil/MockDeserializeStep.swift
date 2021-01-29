// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

import ClientRuntime

public struct MockDeserializeStep: MiddlewareStack {
    
    public typealias Context = HttpContext
 
    public var orderedMiddleware: OrderedGroup<SdkHttpRequest,
                                               SdkHttpRequest,
                                               HttpContext> = OrderedGroup<SdkHttpRequest,
                                                                           SdkHttpRequest,
                                                                           HttpContext>()
    
    public var id: String = "MockDeserializeStep"
    
    public typealias MInput = SdkHttpRequest
    
    public typealias MOutput = SdkHttpRequest
    
    public init() {}
}
