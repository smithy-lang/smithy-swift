//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(SchemaBasedSerde)
import enum Smithy.Prelude
@_spi(SchemaBasedSerde)
import class Smithy.Schema
@_spi(SchemaBasedSerde)
import protocol Smithy.SchemaExtension
@_spi(SchemaBasedSerde)
import var Smithy.schemaExtensionUniqueIndexCounter

/// Stores the UTF-8 bytes for the JSON string representation of this member's JSON name.  The
/// jsonName trait is ignored and the member name is used.
///
/// Bytes may be reused when this member is sent again, increasing performance by not requiring
/// recalculation of the JSON bytes.  The tradeoff is the extra memory consumed to store the bytes
/// in this schema extension.
///
/// Bytes include leading & trailing double-quotes, and all characters requiring escaping in JSON
/// have been escaped.  The trailing colon is appended as well.
final class MemberNameExtension: SchemaExtension {

    static let uniqueIndex = schemaExtensionUniqueIndexCounter.getNextIndex()

    let name: [UInt8]?

    init(schema: Schema) throws {
        let memberName = schema.id.member
        self.name = try memberName.map { try Self.writeKey(name: $0) }
    }

    static func writeKey(name: String) throws -> [UInt8] {
        // Create a Serializer & use it to write the key to a JSON string,
        // surrounded by double quotes.
        let serializer = Serializer(usesJSONNameTrait: false)
        try serializer.writeString(Smithy.Prelude.stringSchema, name)

        // Get the data, append a colon (UTF-8 58) to the end, and create a new array
        // to trim extra capacity and flatten.
        var data = try serializer.data
        data.append(58)
        return [UInt8](data)
    }
}
