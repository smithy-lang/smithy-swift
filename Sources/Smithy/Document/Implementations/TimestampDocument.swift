//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Date

@_spi(SmithyDocumentImpl)
public struct TimestampDocument: SmithyDocument {
    public var type: ShapeType { .timestamp }
    let value: Date

    public init(value: Date) {
        self.value = value
    }

    public func asTimestamp() throws -> Date {
        value
    }
}
