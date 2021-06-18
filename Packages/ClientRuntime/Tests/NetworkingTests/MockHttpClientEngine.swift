/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import Foundation
import AwsCommonRuntimeKit
@testable import ClientRuntime

class MockHttpClientEngine: HttpClientEngine {
    
    let eventLoopGroup: EventLoopGroup
    
    convenience init() {
        let shutDownOptions = ShutDownCallbackOptions { semaphore in
            semaphore.signal()
        }
        let eventLoopGroup = EventLoopGroup(threadCount: 1, shutDownOptions: shutDownOptions)
        try! self.init(eventLoopGroup: eventLoopGroup)
    }
    
    required init(eventLoopGroup: EventLoopGroup) throws {
        self.eventLoopGroup = eventLoopGroup
    }
    
    func execute(request: SdkHttpRequest) -> SdkFuture<HttpResponse> {
        let future = SdkFuture<HttpResponse>()
        future.fulfill(successHttpResponse(request: request))
        return future
    }
    
    func close() {
        //do nothing cuz fake engine
    }
    
    func successHttpResponse(request: SdkHttpRequest) -> HttpResponse {
        return HttpResponse(body: HttpBody.empty, statusCode: HttpStatusCode.ok)
    }
    
    func executeWithClosure(request: SdkHttpRequest, completion: @escaping NetworkResult) {
        completion(.success(successHttpResponse(request: request)))
    }
}
