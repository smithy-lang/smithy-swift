/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import Smithy
import SmithyHTTPAPI
import Foundation
import AwsCommonRuntimeKit
@testable import ClientRuntime

class MockHttpClientEngine: HTTPClient {
    func successHttpResponse(request: SmithyHTTPAPI.HTTPRequest) -> HTTPResponse {
        return HTTPResponse(headers: request.headers, body: ByteStream.empty, statusCode: HTTPStatusCode.ok)
    }

    func send(request: SmithyHTTPAPI.HTTPRequest) async throws -> HTTPResponse {
        return successHttpResponse(request: request)
    }
}
