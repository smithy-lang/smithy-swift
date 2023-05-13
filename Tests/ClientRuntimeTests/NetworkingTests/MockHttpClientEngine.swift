/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import Foundation
import AwsCommonRuntimeKit
@testable import ClientRuntime

class MockHttpClientEngine: HttpClientEngine {
    func successHttpResponse(request: SdkHttpRequest) -> HttpResponse {
        return HttpResponse(headers: request.headers ?? Headers(), body: HttpBody.empty, statusCode: HttpStatusCode.ok)
    }

    func execute(request: SdkHttpRequest) async throws -> HttpResponse {
        return successHttpResponse(request: request)
    }
}
