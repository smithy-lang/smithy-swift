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

/// Stores the UTF-8 bytes for the JSON string representation of this member's JSON name.  If there
/// is a JSON name trait on this member, it is used in place of the member component of the shape ID.
///
/// Bytes may be reused when this member is sent again, increasing performance by not requiring
/// recalculation of the JSON bytes.  The tradeoff is the extra memory consumed to store the bytes
/// in this schema extension.
///
/// Bytes include leading & trailing double-quotes, and all characters requiring escaping in JSON
/// have been escaped.  The trailing colon is appended as well.
final class JSONNameExtension: SchemaExtension {

    static let uniqueIndex = schemaExtensionUniqueIndexCounter.getNextIndex()

    let name: [UInt8]?

    init(schema: Schema) throws {
        let jsonName = schema.getTrait(JSONNameTrait.self)?.name ?? schema.id.member
        self.name = try jsonName.map { try MemberNameExtension.writeKey(name: $0) }
    }
}
