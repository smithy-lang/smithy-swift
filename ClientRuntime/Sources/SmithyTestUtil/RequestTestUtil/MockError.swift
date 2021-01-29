// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

import ClientRuntime

public struct MockError: HttpResponseBinding {
    public init(httpResponse: HttpResponse, decoder: ResponseDecoder?) throws {}
}
