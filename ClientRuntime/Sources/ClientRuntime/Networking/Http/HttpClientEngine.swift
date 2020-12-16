/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

public protocol HttpClientEngine {
    func execute(request: SdkHttpRequest, completion: @escaping NetworkResult)
    func close()
}
