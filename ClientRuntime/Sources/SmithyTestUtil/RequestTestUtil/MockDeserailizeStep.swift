// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.
import ClientRuntime
///Mock handler that just returns the request
public struct MockHandler: Handler {
    
    public typealias Input = SdkHttpRequest
    
    public typealias Output = SdkHttpRequest
    
    public func handle(context: HttpContext, input: Input) -> Result<SdkHttpRequest, Error> {
        return .success(input)
    }
}
