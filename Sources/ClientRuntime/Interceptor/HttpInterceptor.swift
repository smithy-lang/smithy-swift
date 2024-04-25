//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public protocol HttpInterceptor<InputType, OutputType>: Interceptor
where
    RequestType == SdkHttpRequest,
    ResponseType == HttpResponse,
    AttributesType == HttpContext {}
