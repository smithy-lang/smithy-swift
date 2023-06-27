/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
import AwsCommonRuntimeKit

public protocol HttpClientEngine {
    func execute(request: SdkHttpRequest, bidirectional: Bool) async throws -> HttpResponse
}
