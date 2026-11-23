//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(SchemaBasedSerde)
import class Smithy.EC2QueryNameTrait
@_spi(SchemaBasedSerde)
import class Smithy.Schema
@_spi(SchemaBasedSerde)
import protocol Smithy.SchemaExtension
@_spi(SchemaBasedSerde)
import var Smithy.schemaExtensionUniqueIndexCounter
@_spi(SchemaBasedSerde)
import class Smithy.XMLNameTrait

/// Stores the percent-encoded UTF-8 bytes for a member's awsQuery key segment.
///
/// The name is the member's `xmlName` if present, else the member name.  For list & map members,
/// the member name is `member`, `key`, or `value`.
///
/// https://smithy.io/2.0/aws/protocols/aws-query-protocol.html#query-key-resolution
final class AWSQueryNameExtension: SchemaExtension {

    static let uniqueIndex = schemaExtensionUniqueIndexCounter.getNextIndex()

    let name: [UInt8]

    init(schema: Schema) throws {
        let name = schema.getTrait(XMLNameTrait.self)?.name ?? schema.id.member ?? ""
        self.name = Serializer.percentEncoded(name)
    }
}

/// Stores the percent-encoded UTF-8 bytes for a structure member's ec2Query key segment.
///
/// The name is the member's `ec2QueryName` if present, else its `xmlName` with the first
/// letter capitalized, else the member name with the first letter capitalized.
///
/// https://smithy.io/2.0/aws/protocols/aws-ec2-query-protocol.html#query-key-resolution
final class EC2QueryNameExtension: SchemaExtension {

    static let uniqueIndex = schemaExtensionUniqueIndexCounter.getNextIndex()

    let name: [UInt8]

    init(schema: Schema) throws {
        let name = if let ec2QueryName = schema.getTrait(EC2QueryNameTrait.self)?.name {
            ec2QueryName
        } else {
            (schema.getTrait(XMLNameTrait.self)?.name ?? schema.id.member ?? "").capitalizingFirstLetter
        }
        self.name = Serializer.percentEncoded(name)
    }
}

private extension String {

    var capitalizingFirstLetter: String {
        prefix(1).uppercased() + dropFirst()
    }
}
