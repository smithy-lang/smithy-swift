/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import protocol SmithyHTTPAPI.HTTPClient
import class SmithyHTTPAPI.SdkHttpRequest
import class SmithyHTTPAPI.HttpResponse
import ClientRuntime

public class ProtocolTestClient {
    public init() {}
}

public enum TestCheckError: Error {
    case actual(SdkHttpRequest)
}

extension ProtocolTestClient: HTTPClient {
    public func send(request: SdkHttpRequest) async throws -> HttpResponse {
        throw TestCheckError.actual(request)
    }
}

public class ProtocolTestIdempotencyTokenGenerator: ClientRuntime.IdempotencyTokenGenerator {
    public init() {}

    public func generateToken() -> String {
        return "00000000-0000-4000-8000-000000000000"
    }
}
