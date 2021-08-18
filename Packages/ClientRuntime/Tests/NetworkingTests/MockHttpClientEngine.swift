/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import Foundation
import AwsCommonRuntimeKit
@testable import ClientRuntime

class MockHttpClientEngine: HttpClientEngine {    
    func execute(request: SdkHttpRequest) -> SdkFuture<HttpResponse> {
        let future = SdkFuture<HttpResponse>()
        future.fulfill(successHttpResponse(request: request))
        return future
    }
    
    func close() {
        //do nothing cuz fake engine
    }
    
    func successHttpResponse(request: SdkHttpRequest) -> HttpResponse {
        return HttpResponse(headers: request.headers, body: HttpBody.empty, statusCode: HttpStatusCode.ok)
    }
    
    func executeWithClosure(request: SdkHttpRequest, completion: @escaping NetworkResult) {
        completion(.success(successHttpResponse(request: request)))
    }
}
