/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import Foundation
@testable import ClientRuntime

class MockHttpClientEngine: HttpClientEngine {
    func close() {
        //do nothing cuz fake engine
    }
    
    func successHttpResponse(request: SdkHttpRequest) -> HttpResponse {
        return HttpResponse(body: HttpBody.empty, statusCode: HttpStatusCode.ok)
    }
    
    func execute(request: SdkHttpRequest, completion: @escaping NetworkResult) {
        completion(.success(successHttpResponse(request: request)))
    }
}
