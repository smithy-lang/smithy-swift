//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(SchemaBasedSerde)
import class Smithy.OriginalShapeIDTrait
@_spi(SchemaBasedSerde)
import class Smithy.Schema
@_spi(SchemaBasedSerde)
import protocol Smithy.SchemaExtension
@_spi(SchemaBasedSerde)
import var Smithy.schemaExtensionUniqueIndexCounter
@_spi(SchemaBasedSerde)
import class Smithy.XMLAttributeTrait
@_spi(SchemaBasedSerde)
import class Smithy.XMLNamespaceTrait
@_spi(SchemaBasedSerde)
import class Smithy.XMLNameTrait

/// Stores the UTF-8 bytes used to write a member as an XML element or attribute, so they are only
/// computed the first time the member is serialized.
///
/// For a structure or union member, the name is the member's `xmlName` if present, else the member name.
/// For a list member, it is the `xmlName` of the list's member if present, else `member`; for a map key
/// or value, the `xmlName` of the key or value member if present, else `key` or `value`.
final class XMLNameExtension: SchemaExtension {

    static let uniqueIndex = schemaExtensionUniqueIndexCounter.getNextIndex()

    /// The element or attribute name.
    let name: [UInt8]

    /// The namespace declaration for this member's element, including a leading space,
    /// i.e. ` xmlns="http://example.com"`, or empty if the member has no `xmlNamespace`.
    let namespace: [UInt8]

    /// `true` if this member is written as an attribute of its enclosing structure's element.
    let isAttribute: Bool

    init(schema: Schema) throws {
        let name = schema.getTrait(XMLNameTrait.self)?.name ?? schema.id.member ?? schema.id.name
        self.name = Serializer.escaped(name, isAttribute: true)
        self.namespace = Serializer.namespaceDeclaration(schema.getTrait(XMLNamespaceTrait.self))
        self.isAttribute = schema.hasTrait(XMLAttributeTrait.self)
    }
}

/// Stores the UTF-8 bytes used to write a shape as the root element of an XML document.
///
/// The root element is named by, in order of precedence, the `xmlName` of the member being written
/// (for an HTTP payload member), the `xmlName` of the shape, or the shape's name as modeled.  For a
/// synthesized operation input, the name as modeled is the one recorded by its `OriginalShapeIDTrait`.
/// Its namespace is the member's `xmlNamespace`, else the shape's.
final class XMLRootNameExtension: SchemaExtension {

    static let uniqueIndex = schemaExtensionUniqueIndexCounter.getNextIndex()

    /// The root element name.
    let name: [UInt8]

    /// The namespace declaration for the root element, including a leading space, or `nil` if neither
    /// the member nor the shape has an `xmlNamespace`.
    let namespace: [UInt8]?

    init(schema: Schema) throws {
        let shape = schema.containerType != nil ? (schema.target ?? schema) : schema
        let name = schema.getTrait(XMLNameTrait.self)?.name
            ?? shape.getTrait(XMLNameTrait.self)?.name
            ?? shape.getTrait(OriginalShapeIDTrait.self)?.originalID.name
            ?? shape.id.name
        self.name = Serializer.escaped(name, isAttribute: true)
        let namespace = schema.getTrait(XMLNamespaceTrait.self) ?? shape.getTrait(XMLNamespaceTrait.self)
        self.namespace = namespace.map { Serializer.namespaceDeclaration($0) }
    }
}

/// Stores whether a structure or union has members written as XML attributes.
///
/// Attributes must be written into the element's start tag before any of its content, so a structure
/// with attribute members has them written in a pass before its other members.
final class XMLAttributeMembersExtension: SchemaExtension {

    static let uniqueIndex = schemaExtensionUniqueIndexCounter.getNextIndex()

    let hasAttributeMembers: Bool

    init(schema: Schema) throws {
        self.hasAttributeMembers = schema.members.contains { $0.hasTrait(XMLAttributeTrait.self) }
    }
}
