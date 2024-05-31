//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SmithyHTTPAPI

public struct MockOutput {
    public var value: Int = 0
    public var headers: Headers = Headers()

    public init() {}

    public static func responseClosure(_ httpResponse: HttpResponse) async throws -> MockOutput {
        var value = MockOutput()
        value.value = httpResponse.statusCode.rawValue
        value.headers = httpResponse.headers
        return value
    }
}
