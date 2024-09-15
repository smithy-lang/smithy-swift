//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(SmithyDocumentImpl)
public struct BooleanDocument: Document {
    public var type: ShapeType { .boolean }
    let value: Bool

    public init(value: Bool) {
        self.value = value
    }

    public func asBoolean() throws -> Bool {
        value
    }
}
