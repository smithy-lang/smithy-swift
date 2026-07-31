//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
@_spi(SchemaBasedSerde)
import class Smithy.JSONNameTrait
@_spi(SchemaBasedSerde)
import enum Smithy.Prelude
@_spi(SchemaBasedSerde)
import class Smithy.Schema
@_spi(SchemaBasedSerde)
import protocol Smithy.SchemaExtension
@_spi(SchemaBasedSerde)
import var Smithy.schemaExtensionUniqueIndexCounter

/// Stores the UTF-8 bytes for the JSON string representation of this member's JSON name.
///
/// Bytes may be reused when this member is sent again, increasing performance by not requiring
/// recalculation of theJSON bytes.  The tradeoff is the extra memory consumed to store the bytes
/// in this schema extension.
///
/// Bytes include leading & trailing double-quotes, and all characters requiring escaping in JSON
/// have been escaped.  The trailing colon is not included.
final class MemberJSONNameExtension: SchemaExtension {

    static let uniqueIndex = schemaExtensionUniqueIndexCounter.getNextIndex()

    let nameWithoutJSONNameTrait: Data?
    let nameWithJSONNameTrait: Data?

    required init(schema: Schema) throws {
        let memberName = schema.id.member
        let jsonName = schema.getTrait(JSONNameTrait.self)?.name ?? memberName
        self.nameWithoutJSONNameTrait = try memberName.map { try Self.writeKey(name: $0) }
        self.nameWithJSONNameTrait = try jsonName.map { try Self.writeKey(name: $0) }
    }

    @inline(always)
    private static func writeKey(name: String) throws -> Data {
        let serializer = Serializer(usesJSONNameTrait: false)
        try serializer.writeString(Smithy.Prelude.stringSchema, name)
        var data = try serializer.data
        data.append(58) // append a colon after the key
        return Data(data) // trims excess capacity & flattens the source Data
    }
}
