/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import class Smithy.Context
import protocol SmithyHTTPAPI.HTTPClient
import class SmithyHTTPAPI.HTTPRequest
import class SmithyHTTPAPI.HTTPResponse

/// this class will implement Handler per new middleware implementation
public class SdkHttpClient: ExecuteRequest {

    let engine: HTTPClient

    public init(engine: HTTPClient, config: HttpClientConfiguration) {
        self.engine = engine
    }

    public func execute(request: HTTPRequest, attributes: Smithy.Context) async throws -> HTTPResponse {
        if attributes.shouldForceH2(), let crtEngine = engine as? CRTClientEngine {
            return try await crtEngine.executeHTTP2Request(request: request)
        } else {
            return try await engine.send(request: request)
        }
    }

    func send(request: HTTPRequest) async throws -> HTTPResponse {
        return try await engine.send(request: request)
    }
}
