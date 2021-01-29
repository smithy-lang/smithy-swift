// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.
import ClientRuntime

public struct MockHandler: Handler {
    
    public typealias Input = SdkHttpRequest
    
    public typealias Output = SdkHttpRequest
    
    let resultType: (_ context: HttpContext, _ input: Input) -> Result<SdkHttpRequest, Error>
    
    public func handle(context: HttpContext, input: Input) -> Result<SdkHttpRequest, Error> {
        return resultType(context, input)
    }
}
