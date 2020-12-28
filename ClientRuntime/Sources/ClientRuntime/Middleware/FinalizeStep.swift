// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

// Performs final preparations needed before sending the message. The
// message should already be complete by this stage, and is only alternated
// to meet the expectations of the recipient, (e.g. Retry and AWS SigV4
// request signing)
//
// Takes Request, and returns result or error.
//
// Receives result or error from Deserialize step.
public struct FinalizeStep<Output: HttpResponseBinding>: MiddlewareStack {
    
    public var orderedMiddleware: OrderedGroup<SdkHttpRequest, Output> = OrderedGroup<SdkHttpRequest, Output>()
    
    public var id: String = "FinalizeStep"
    
    public typealias MInput = SdkHttpRequest
    
    public typealias MOutput = Output
}
