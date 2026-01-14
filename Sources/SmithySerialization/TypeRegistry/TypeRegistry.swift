//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class Smithy.Schema
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

    public func codeLookup(serviceSchema: Schema, code: String) -> Entry? {
        let useQueryCompatibility = serviceSchema.traits[queryCompatibleTrait] != nil
        return idMap.values.first {
            code == Self.code(useQueryCompatibility, $0.schema)
        }
    }

    private static func code(_ useQueryCompatibility: Bool, _ schema: Schema) -> String {
        if useQueryCompatibility,
            case .object(let object) = schema.traits[queryErrorTrait],
            case .string(let code) = object["code"] {
            code
        } else {
            schema.id.name
        }
    }
}

private let queryCompatibleTrait = ShapeID("aws.protocols", "awsQueryCompatible")
private let queryErrorTrait = ShapeID("aws.protocols", "awsQueryError")
