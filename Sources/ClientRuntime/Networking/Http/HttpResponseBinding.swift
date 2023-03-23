/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

public protocol HttpResponseBinding {
    init(httpResponse: HttpResponse, decoder: ResponseDecoder?) throws
}
