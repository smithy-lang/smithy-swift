// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

@testable import ClientRuntime

struct MockInput: HttpRequestBinding {
    func buildHttpRequest(encoder: RequestEncoder, idempotencyTokenGenerator: IdempotencyTokenGenerator) throws -> SdkHttpRequestBuilder {
        return SdkHttpRequestBuilder()
    }
}
