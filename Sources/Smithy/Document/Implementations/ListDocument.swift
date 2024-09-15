//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(SmithyDocumentImpl)
public struct ListDocument: Document {
    public var type: ShapeType { .list }
    let value: [any Document]

    public init(value: [any Document]) {
        self.value = value
    }

    public func asList() throws -> [any Document] {
        return value
    }

    public func size() -> Int {
        value.count
    }
}
