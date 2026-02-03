//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import protocol SmithyHTTPAPI.HTTPClient
import class SmithyHTTPAPI.HTTPRequest
import class SmithyHTTPAPI.HTTPResponse

public class ProtocolResponseTestClient {
    let httpResponse: HTTPResponse

    public init(httpResponse: HTTPResponse) {
        self.httpResponse = httpResponse
    }
}

extension ProtocolResponseTestClient: HTTPClient {

    public func send(request: HTTPRequest) async throws -> HTTPResponse {
        httpResponse
    }
}
