//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(SchemaBasedSerde)
import class Smithy.DefaultTrait
@_spi(SchemaBasedSerde)
import class Smithy.RequiredTrait
@_spi(SchemaBasedSerde)
import class Smithy.Schema
@_spi(SchemaBasedSerde)
import protocol Smithy.SchemaExtension
@_spi(SchemaBasedSerde)
import var Smithy.schemaExtensionUniqueIndexCounter
@_spi(SchemaBasedSerde)
import class Smithy.XMLAttributeTrait
@_spi(SchemaBasedSerde)
import class Smithy.XMLFlattenedTrait
@_spi(SchemaBasedSerde)
import class Smithy.XMLNameTrait

/// Stores, for a structure or union schema, the members indexed by the XML name they are read from.
///
/// It is created the first time the structure is deserialized and reused after that, so the names of the
/// members & their XML traits are only resolved once.
final class XMLMemberLookupExtension: SchemaExtension {

    static let uniqueIndex = schemaExtensionUniqueIndexCounter.getNextIndex()

    struct ElementMember {
        let schema: Schema
        /// `true` if this member is a list or map that is flattened into its enclosing structure.
        let isFlattened: Bool
    }

    /// Members that are read from child elements, keyed by element name.
    let elementMembers: [String: ElementMember]

    /// Members that are read from attributes of the structure's element, with the attribute name.
    let attributeMembers: [(name: String, schema: Schema)]

    /// Members that are `@required` and have no `@default`, which are pre-filled with a zero value.
    let requiredMembers: [Schema]

    init(schema: Schema) throws {
        var elementMembers = [String: ElementMember]()
        var attributeMembers = [(name: String, schema: Schema)]()
        var requiredMembers = [Schema]()
        for member in schema.members {
            if member.hasTrait(RequiredTrait.self) && !member.hasTrait(DefaultTrait.self) {
                requiredMembers.append(member)
            }
            guard let name = member.getTrait(XMLNameTrait.self)?.name ?? member.id.member else { continue }
            if member.hasTrait(XMLAttributeTrait.self) {
                attributeMembers.append((name, member))
            } else {
                let targetType = member.target?.type
                let isCollection = targetType == .list || targetType == .set || targetType == .map
                let isFlattened = isCollection && member.hasTrait(XMLFlattenedTrait.self)
                elementMembers[name] = ElementMember(schema: member, isFlattened: isFlattened)
            }
        }
        self.elementMembers = elementMembers
        self.attributeMembers = attributeMembers
        self.requiredMembers = requiredMembers
    }
}
