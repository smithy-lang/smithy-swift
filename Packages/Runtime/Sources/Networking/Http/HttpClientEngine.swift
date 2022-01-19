/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
import AwsCommonRuntimeKit

public protocol HttpClientEngine {
    func executeWithClosure(request: SdkHttpRequest, completion: @escaping NetworkResult)
    func execute(request: SdkHttpRequest) -> SdkFuture<HttpResponse>
    func close()
}
