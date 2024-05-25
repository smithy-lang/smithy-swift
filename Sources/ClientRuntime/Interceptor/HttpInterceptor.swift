//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class SmithyAPI.OperationContext
import class SmithyHTTPAPI.SdkHttpRequest
import class SmithyHTTPAPI.HttpResponse

public protocol HttpInterceptor<InputType, OutputType>: Interceptor
where
    RequestType == SdkHttpRequest,
    ResponseType == HttpResponse,
    AttributesType == OperationContext {}
