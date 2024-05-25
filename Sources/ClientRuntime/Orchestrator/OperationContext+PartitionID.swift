//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct SmithyAPI.AttributeKey
import protocol SmithyAPI.HasAttributes
import class SmithyHTTPAPI.HttpResponse

extension HasAttributes {

    var partitionID: String? {
        get {
            get(key: partitionIDKey)
        }
        set {
            set(key: partitionIDKey, value: newValue)
        }
    }
}

private let partitionIDKey = AttributeKey<String>(name: "partitionIDKey")
