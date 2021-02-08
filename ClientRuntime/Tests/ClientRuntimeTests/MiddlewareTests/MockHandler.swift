// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

@testable import ClientRuntime

struct MockHandler<Output: HttpResponseBinding, OutputError: HttpResponseBinding>: Handler where OutputError: Error {
    
    typealias Context = HttpContext
    typealias TestHandlerCallback = (Context, SdkHttpRequest) -> Result<DeserializeOutput<Output, OutputError>, Error>
    let handleCallback: TestHandlerCallback
    
    init(handleCallback: @escaping TestHandlerCallback) {
        self.handleCallback = handleCallback
    }
    func handle(context: Context, input: SdkHttpRequest) -> Result<DeserializeOutput<Output, OutputError>, Error> {
        return self.handleCallback(context, input)

    }
    
    typealias Input = SdkHttpRequest
    
    typealias Output = DeserializeOutput<Output, OutputError>
}
