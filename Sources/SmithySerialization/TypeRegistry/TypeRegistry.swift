//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(SchemaBasedSerde)
import struct Smithy.Schema
@_spi(SchemaBasedSerde)
import struct Smithy.ShapeID

@_spi(SchemaBasedSerde)
public struct TypeRegistry: Sendable {

    public struct Entry: Sendable {
        private let _schema: @Sendable () -> Schema
        public let swiftType: any DeserializableShape.Type

        public init(
            schema: @escaping @Sendable @autoclosure () -> Schema,
            swiftType: DeserializableShape.Type
        ) {
            self._schema = schema
            self.swiftType = swiftType
        }

        public var schema: Schema { _schema() }
    }

    private let entries: [Entry]

    public init(_ entries: [Entry]) {
        self.entries = entries
    }

    public func find(matcher: (Entry) throws -> Bool) rethrows -> Entry? {
        try entries.first { try matcher($0) }
    }
}
