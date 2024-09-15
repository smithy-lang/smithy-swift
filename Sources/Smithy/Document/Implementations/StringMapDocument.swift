//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(SmithyDocumentImpl)
public struct StringMapDocument: Document {
    public var type: ShapeType { .map }
    let value: [String: any Document]

    public init(value: [String: any Document]) {
        self.value = value
    }

    public func asStringMap() throws -> [String: any Document] {
        return value
    }

    public func size() -> Int {
        value.count
    }

    public func getMember(_ memberName: String) throws -> (any Document)? {
        value[memberName]
    }

    public static func ==(_ lhs: StringMapDocument, _ rhs: StringMapDocument) -> Bool {
        false
    }
}
