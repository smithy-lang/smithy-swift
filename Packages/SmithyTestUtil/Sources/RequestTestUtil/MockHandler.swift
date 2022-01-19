//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Runtime

public struct MockHandler<Output: HttpResponseBinding, OutputError: HttpResponseBinding>: Handler {
    
    public typealias Context = HttpContext
    public typealias MockHandlerCallback = (Context, SdkHttpRequest) -> Result<OperationOutput<Output>, MiddlewareError>
    let handleCallback: MockHandlerCallback
    public init(handleCallback: @escaping MockHandlerCallback) {
        self.handleCallback = handleCallback
    }
    public func handle(context: Context, input: SdkHttpRequest) -> Result<OperationOutput<Output>, MiddlewareError> {
        return self.handleCallback(context, input)

    }
    
    public typealias Input = SdkHttpRequest
    
    public typealias Output = OperationOutput<Output>
    public typealias MiddlewareError = SdkError<OutputError>
}
