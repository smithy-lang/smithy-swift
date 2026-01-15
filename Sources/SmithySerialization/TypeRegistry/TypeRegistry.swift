//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Smithy.AWSQueryCompatibleTrait
import struct Smithy.AWSQueryErrorTrait
import struct Smithy.Schema
import struct Smithy.ShapeID

public struct TypeRegistry {

    public class Entry {
        private let _schema: () -> Schema
        public let swiftType: DeserializableShape.Type

        public init(
            schema: @escaping @autoclosure () -> Schema,
            swiftType: DeserializableShape.Type
        ) {
            self._schema = schema
            self.swiftType = swiftType
        }

        public var schema: Schema { _schema() }
    }

    private let idMap: [ShapeID: Entry]

    public init(_ entries: [Entry]) {
        self.idMap = Dictionary(uniqueKeysWithValues: entries.map { ($0.schema.id, $0) })
    }

    public subscript(shapeID: ShapeID) -> Entry? {
        idMap[shapeID]
    }

    public func codeLookup(serviceSchema: Schema, code: String) throws -> Entry? {
        let useQueryCompatibility = serviceSchema.hasTrait(AWSQueryCompatibleTrait.self)
        return try idMap.values.first {
            try code == Self.code(useQueryCompatibility, $0.schema)
        }
    }

    private static func code(_ useQueryCompatibility: Bool, _ schema: Schema) throws -> String {
        if useQueryCompatibility, let code = try schema.getTrait(AWSQueryErrorTrait.self)?.code {
            code
        } else {
            schema.id.name
        }
    }
}
