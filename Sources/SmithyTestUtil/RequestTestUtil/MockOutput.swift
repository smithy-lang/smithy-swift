//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import ClientRuntime

public struct MockOutput: HttpResponseBinding {
    public let value: Int
    public let headers: Headers
    public init(httpResponse: ClientRuntime.HttpResponse, decoder: ClientRuntime.ResponseDecoder?, messageDecoder: ClientRuntime.MessageDecoder?) throws {
        self.value = httpResponse.statusCode.rawValue
        self.headers = httpResponse.headers
    }
}
