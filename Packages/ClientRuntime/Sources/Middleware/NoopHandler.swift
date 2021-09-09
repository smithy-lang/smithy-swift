//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
	
public struct NoopHandler<Output: HttpResponseBinding, OutputError: HttpResponseBinding>: Handler {
    public init() {
    }
    public func handle(context: HttpContext, input: SdkHttpRequest) -> Result<OperationOutput<Output>, SdkError<OutputError>> {
        let output = OperationOutput<Output>(httpResponse: HttpResponse())
        return .success(output)
    }
}
