/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import protocol SmithyHTTPAPI.HTTPClient
import class SmithyHTTPAPI.HTTPRequest
import class SmithyHTTPAPI.HTTPResponse
import ClientRuntime

public class ProtocolTestClient {
    public init() {}
}

public enum TestCheckError: Error {
    case actual(HTTPRequest)
}

extension ProtocolTestClient: HTTPClient {
    public func send(request: HTTPRequest) async throws -> HTTPResponse {
        throw TestCheckError.actual(request)
    }
}

public class ProtocolTestIdempotencyTokenGenerator: ClientRuntime.IdempotencyTokenGenerator {
    public init() {}

    public func generateToken() -> String {
        return "00000000-0000-4000-8000-000000000000"
    }
}
