/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

public protocol HttpRequestBinding {

  // Build the HttpRequest using the input method and path
    func buildHttpRequest(encoder: RequestEncoder,
                          idempotencyTokenGenerator: IdempotencyTokenGenerator) throws -> SdkHttpRequestBuilder
}
