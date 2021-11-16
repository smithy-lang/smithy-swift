//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
	
public struct NoopHandler<Output: HttpResponseBinding>: Handler {
    public init() {}
    
    public func handle(context: HttpContext, input: SdkHttpRequest) async throws -> OperationOutput<Output> {
        let output = OperationOutput<Output>(httpResponse: HttpResponse())
        return output
    }
}
