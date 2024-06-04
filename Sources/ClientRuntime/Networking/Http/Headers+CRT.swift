//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct SmithyHTTPAPI.Headers
import AwsCommonRuntimeKit

extension Headers {
    public func toHttpHeaders() -> [HTTPHeader] {
        headers.map {
            HTTPHeader(name: $0.name, value: $0.value.joined(separator: ","))
        }
    }

    init(httpHeaders: [HTTPHeader]) {
        self.init()
        addAll(httpHeaders: httpHeaders)
    }

    public mutating func addAll(httpHeaders: [HTTPHeader]) {
        httpHeaders.forEach {
            add(name: $0.name, value: $0.value)
        }
    }
}
