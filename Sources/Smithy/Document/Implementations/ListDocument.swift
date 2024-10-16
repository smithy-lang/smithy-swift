//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(SmithyDocumentImpl)
public struct ListDocument: SmithyDocument {
    public var type: ShapeType { .list }
    let value: [SmithyDocument]

    public init(value: [SmithyDocument]) {
        self.value = value
    }

    public func asList() throws -> [SmithyDocument] {
        return value
    }

    public func size() -> Int {
        value.count
    }
}
