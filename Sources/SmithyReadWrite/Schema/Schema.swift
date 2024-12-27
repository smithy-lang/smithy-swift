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

@_spi(SchemaBasedSerde)
public protocol SchemaProtocol: AnyObject {
    var type: ShapeType { get }
    var targetSchema: () -> SchemaProtocol? { get }
    var defaultValue: (any SmithyDocument)? { get }
    var jsonName: String? { get }
    var enumValue: (any SmithyDocument)? { get }
    var memberName: String? { get }
    var isRequired: Bool { get }

    func read(reader: any ShapeDeserializer) throws
    func write(writer: any SmithyWriter) throws
}

public extension SchemaProtocol {

    var lastResortDefaultValue: any SmithyDocument {
        get throws {
            switch type {
            case .structure, .union, .map: return StringMapDocument(value: [:])
            case .string, .enum: return StringDocument(value: "")
            case .integer, .intEnum: return IntegerDocument(value: 0)
            case .boolean: return BooleanDocument(value: false)
            case .blob: return BlobDocument(value: Data())
            case .timestamp: return TimestampDocument(value: Date(timeIntervalSince1970: 0.0))
            case .bigDecimal: return BigDecimalDocument(value: 0.0)
            case .bigInteger: return BigIntegerDocument(value: 0)
            case .byte: return ByteDocument(value: 0)
            case .document: return NullDocument()
            case .list, .set: return ListDocument(value: [])
            case .short: return ShortDocument(value: 0)
            case .long: return LongDocument(value: 0)
            case .float: return FloatDocument(value: 0.0)
            case .double: return DoubleDocument(value: 0.0)
            case .member, .service, .resource, .operation:
                throw ReaderError.invalidSchema("Last resort not defined for type \(type)")
            }
        }
    }
}

@_spi(SchemaBasedSerde)
public protocol MemberProtocol<Base> {
    associatedtype Base
    var memberSchema: SchemaProtocol { get }
    func performRead(base: inout Base, reader: any ShapeDeserializer) throws
    func performWrite(base: Base, writer: any SmithyWriter) throws
}

@_spi(SchemaBasedSerde)
public class Schema<Base>: SchemaProtocol {

    public struct MemberContainer {
        public let member: any MemberProtocol<Base>

        public init(member: any MemberProtocol<Base>) {
            self.member = member
        }

        public func performRead(base: inout Base, reader: any ShapeDeserializer) throws {
            try member.performRead(base: &base, reader: reader)
        }

        public func performWrite(base: Base, writer: any SmithyWriter) throws {
            try member.performWrite(base: base, writer: writer)
        }
    }

    public struct Member<Target>: MemberProtocol {
        public let memberSchema: any SchemaProtocol
        let readBlock: (inout Base, any ShapeDeserializer) throws -> Void
        let writeBlock: (Base, any SmithyWriter) throws -> Void

        public init(
            memberSchema: any SchemaProtocol,
            readBlock: @escaping (inout Base, any ShapeDeserializer) throws -> Void = { _, _ in },
            writeBlock: @escaping (Base, any SmithyWriter) throws -> Void = { _, _ in }
        ) {
            self.memberSchema = memberSchema
            self.readBlock = readBlock
            self.writeBlock = writeBlock
        }

        public func performRead(base: inout Base, reader: any ShapeDeserializer) throws {
            try readBlock(&base, reader)
        }

        public func performWrite(base: Base, writer: any SmithyWriter) throws {
            try writeBlock(base, writer)
        }
    }

    public let type: ShapeType
    public let members: [MemberContainer]
    public let targetSchemaSpecific: () -> Schema<Base>?
    public let memberName: String?
    public let jsonName: String?
    public let enumValue: (any SmithyDocument)?
    public let timestampFormat: SmithyTimestamps.TimestampFormat?
    public let isRequired: Bool
    public let defaultValue: (any Smithy.SmithyDocument)?


    public var targetSchema: () -> (any SchemaProtocol)? { targetSchemaSpecific }

    public init(
        type: ShapeType,
        members: [MemberContainer] = [],
        targetSchema: @escaping () -> Schema<Base>? = { nil },
        memberName: String? = nil,
        jsonName: String? = nil,
        enumValue: (any SmithyDocument)? = nil,
        timestampFormat: SmithyTimestamps.TimestampFormat? = nil,
        isRequired: Bool = false,
        defaultValue: (any Smithy.SmithyDocument)? = nil
    ) {
        self.type = type
        self.members = members
        self.targetSchemaSpecific = targetSchema
        self.memberName = memberName
        self.jsonName = jsonName
        self.enumValue = enumValue
        self.timestampFormat = timestampFormat
        self.isRequired = isRequired
        self.defaultValue = defaultValue
    }

    public func read(reader: any ShapeDeserializer) throws {
        // TODO: implement
    }

    public func write(writer: any SmithyWriter) throws {
        // TODO: implement
    }
}
