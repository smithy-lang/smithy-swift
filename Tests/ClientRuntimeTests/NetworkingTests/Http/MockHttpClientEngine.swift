/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import SmithyHTTPAPI
import SmithyStreamsAPI
import Foundation
import AwsCommonRuntimeKit
@testable import ClientRuntime

class MockHttpClientEngine: HTTPClient {
    func successHttpResponse(request: SdkHttpRequest) -> HttpResponse {
        return HttpResponse(headers: request.headers, body: ByteStream.empty, statusCode: HttpStatusCode.ok)
    }

    func send(request: SdkHttpRequest) async throws -> HttpResponse {
        return successHttpResponse(request: request)
    }
}
