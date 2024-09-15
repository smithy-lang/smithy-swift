//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(SmithyDocumentImpl)
public struct StringMapDocument: SmithyDocument {
    public var type: ShapeType { .map }
    let value: [String: SmithyDocument]

    public init(value: [String: SmithyDocument]) {
        self.value = value
    }

    public func asStringMap() throws -> [String: SmithyDocument] {
        return value
    }

    public func size() -> Int {
        value.count
    }

    public func getMember(_ memberName: String) throws -> SmithyDocument? {
        value[memberName]
    }

    public static func ==(_ lhs: StringMapDocument, _ rhs: StringMapDocument) -> Bool {
        false
    }
}
