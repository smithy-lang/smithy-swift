//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import struct Foundation.Date
@_spi(SmithyDocumentImpl) import Smithy
@_spi(SmithyTimestamps) import SmithyTimestamps

@_spi(SmithyReadWrite)
public protocol SchemaProtocol {
    var id: String { get }
    var type: ShapeType { get }
    var traits: [String: TraitNode] { get }
    var memberName: String? { get }
    var containerType: ShapeType? { get }
}

@_spi(SmithyReadWrite)
public protocol MemberProtocol<Base> {
    associatedtype Base
    var memberSchema: () -> (any SchemaProtocol) { get }
    func performRead(base: inout Base, key: String, reader: any ShapeDeserializer) throws
    func performWrite(base: Base, writer: any SmithyWriter) throws
}

@_spi(SmithyReadWrite)
public struct MemberContainer<Base> {
    public let member: any MemberProtocol<Base>

    public init(member: any MemberProtocol<Base>) {
        self.member = member
    }

    public func performRead(base: inout Base, key: String, reader: any ShapeDeserializer) throws {
        try member.performRead(base: &base, key: key, reader: reader)
    }

    public func performWrite(base: Base, writer: any SmithyWriter) throws {
        try member.performWrite(base: base, writer: writer)
    }
}

@_spi(SmithyReadWrite)
public struct Schema<Base>: SchemaProtocol {

    public struct Member<Target>: MemberProtocol {
        public var memberSchema: () -> (any SchemaProtocol) { { memberSchemaSpecific() } }
        public let memberSchemaSpecific: () -> Schema<Target>
        let readBlock: (inout Base, String, any ShapeDeserializer) throws -> Void
        let writeBlock: (Base, any SmithyWriter) throws -> Void

        public init(
            memberSchema: @escaping () -> Schema<Target>,
            readBlock: @escaping (inout Base, String, any ShapeDeserializer) throws -> Void = { _, _, _ in },
            writeBlock: @escaping (Base, any SmithyWriter) throws -> Void = { _, _ in }
        ) {
            self.memberSchemaSpecific = memberSchema
            self.readBlock = readBlock
            self.writeBlock = writeBlock
        }

        public func performRead(base: inout Base, key: String, reader: any ShapeDeserializer) throws {
            try readBlock(&base, key, reader)
        }

        public func performWrite(base: Base, writer: any SmithyWriter) throws {
            try writeBlock(base, writer)
        }
    }

    public let id: String
    public let type: ShapeType
    public let traits: [String: TraitNode]
    public let factory: (() -> Base)?
    public let members: [MemberContainer<Base>]
    public let targetSchema: () -> Schema<Base>?
    public let memberName: String?
    public let containerType: ShapeType?

    public init(
        id: String,
        type: ShapeType,
        traits: [String: TraitNode] = [:],
        factory: (() -> Base)? = nil,
        members: [MemberContainer<Base>] = [],
        targetSchema: @escaping () -> Schema<Base>? = { nil },
        memberName: String? = nil,
        containerType: ShapeType? = nil,
    ) {
        self.id = id
        self.type = type
        self.traits = traits
        self.factory = factory
        self.members = members
        self.targetSchema = targetSchema
        self.memberName = memberName
        self.containerType = containerType
    }
}

extension SchemaProtocol {

    public var jsonName: String? {
        guard let jsonNameTrait = traits["smithy.api#jsonName"] else { return nil }
        guard case .string(let jsonName) = jsonNameTrait else { return nil }
        return jsonName
    }

    public var enumValue: (any SmithyDocument)? {
        guard let enumValueTrait = traits["smithy.api#enumValue"] else { return nil }
        switch enumValueTrait {
        case .string(let value):
            return StringDocument(value: value)
        case .number(let value):
            return IntegerDocument(value: Int(value.rounded(.toNearestOrAwayFromZero)))
        default:
            fatalError("Unexpected enum value")
        }
    }

    public var isSparse: Bool {
        traits.contains { $0.key == "smithy.api#sparse" }
    }

    public var isRequired: Bool {
        traits.contains { $0.key == "smithy.api#required" }
    }

    public var httpPayload: Bool {
        traits.contains { $0.key == "smithy.api#httpPayload" }
    }

    public var timestampFormat: SmithyTimestamps.TimestampFormat? {
        guard let timestampFormatTrait = traits["smithy.api#timestampFormat"] else { return nil }
        guard case .string(let timestampFormatString) = timestampFormatTrait else { return nil }
        switch timestampFormatString {
        case "date-time":
            return .dateTime
        case "epoch-seconds":
            return .epochSeconds
        case "http-date":
            return .httpDate
        default:
            fatalError("Unexpected value for timestamp format")
        }
    }

    public var defaultValue: (any Smithy.SmithyDocument)? {
        guard let defaultValueTrait = traits["smithy.api#default"] else { return nil }
        return defaultValueTrait.toDocument()
    }
}
