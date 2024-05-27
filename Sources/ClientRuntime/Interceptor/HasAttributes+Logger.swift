//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import protocol Smithy.HasAttributes
import protocol Smithy.LogAgent
import struct Smithy.AttributeKey

extension HasAttributes {

    var logger: LogAgent? {
        get { get(key: loggerKey) }
        set { set(key: loggerKey, value: newValue) }
    }
}

private let loggerKey = AttributeKey<LogAgent>(name: "loggerKey")
