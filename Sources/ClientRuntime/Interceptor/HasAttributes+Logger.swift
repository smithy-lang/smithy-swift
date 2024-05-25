//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import protocol SmithyAPI.HasAttributes
import protocol SmithyAPI.LogAgent
import struct SmithyAPI.AttributeKey

extension HasAttributes {

    var logger: LogAgent? {
        get { get(key: loggerKey) }
        set { set(key: loggerKey, value: newValue) }
    }
}

private let loggerKey = AttributeKey<LogAgent>(name: "loggerKey")
