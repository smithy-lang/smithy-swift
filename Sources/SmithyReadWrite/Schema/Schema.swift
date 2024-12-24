//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Smithy
@_spi(SmithyTimestamps) import SmithyTimestamps

@_spi(SchemaBasedSerde)
public protocol SchemaProtocol: AnyObject {
//    var namespace: String { get }
//    var name: String { get }
    var type: ShapeType { get }

    func read(reader: any SmithyReader) throws
    func write(writer: any SmithyWriter) throws
}

//extension SchemaProtocol {
//
//    public var id: String { ["\(namespace)#\(name)", memberName].compactMap { $0 }.joined(separator: "$") }
//}

@_spi(SchemaBasedSerde)
public class StructureSchema<Base>: SchemaProtocol {

    public struct Member {
        public let memberSchema: () -> SchemaProtocol
        public let targetSchema: () -> SchemaProtocol
        public let readBlock: (inout Base, any ShapeDeserializer) throws -> Void
        public let writeBlock: (Base, any SmithyWriter) throws -> Void

        public init(
            memberSchema: @escaping () -> SchemaProtocol,
            targetSchema: @escaping () -> SchemaProtocol,
            readBlock: @escaping (inout Base, any ShapeDeserializer) throws -> Void,
            writeBlock: @escaping (Base, any SmithyWriter) throws -> Void
        ) {
            self.memberSchema = memberSchema
            self.targetSchema = targetSchema
            self.readBlock = readBlock
            self.writeBlock = writeBlock
        }
    }

//    public let namespace: String
//    public let name: String
    public let type: ShapeType
    public let members: [Member]
    public let memberName: String?

    public init(
        namespace: String = "",
        name: String = "",
        type: ShapeType,
        members: [Member] = [],
        memberName: String? = nil
    ) {
//        self.namespace = namespace
//        self.name = name
        self.type = type
        self.members = members
        self.memberName = memberName
    }

    public func read(reader: any SmithyReader) throws {
        // TODO: implement
    }

    public func write(writer: any SmithyWriter) throws {
        // TODO: implement
    }
}

@_spi(SchemaBasedSerde)
public class ListSchema<Element>: SchemaProtocol {
//    public let namespace: String
//    public let name: String
    public let type: ShapeType
    public let memberSchema: () -> SchemaProtocol
    public let targetSchema: () -> SchemaProtocol
    public let readBlock: (any ShapeDeserializer) throws -> Element
    public let writeBlock: (any SmithyWriter, Element) throws -> Void

    public init(
        namespace: String = "",
        name: String = "",
        type: ShapeType,
        memberSchema: @escaping () -> SchemaProtocol,
        targetSchema: @escaping () -> SchemaProtocol,
        readBlock: @escaping (any ShapeDeserializer) throws -> Element,
        writeBlock: @escaping (any SmithyWriter, Element) throws -> Void
    ) {
//        self.namespace = namespace
//        self.name = name
        self.type = type
        self.memberSchema = memberSchema
        self.targetSchema = targetSchema
        self.readBlock = readBlock
        self.writeBlock = writeBlock
    }

    public func read(reader: any SmithyReader) throws {
        // TODO: implement
    }

    public func write(writer: any SmithyWriter) throws {
        // TODO: implement
    }
}

@_spi(SchemaBasedSerde)
public class MapSchema<Value>: SchemaProtocol {
//    public let namespace: String
//    public let name: String
    public let type: ShapeType
    public let keyMemberSchema: () -> SchemaProtocol
    public let keyTargetSchema: () -> SchemaProtocol
    public let valueMemberSchema: () -> SchemaProtocol
    public let valueTargetSchema: () -> SchemaProtocol
    public let readBlock: (any ShapeDeserializer) throws -> Value
    public let writeBlock: (any SmithyWriter, Value) throws -> Void

    public init(
        namespace: String = "",
        name: String = "",
        type: ShapeType,
        keyMemberSchema: @escaping () -> SchemaProtocol,
        keyTargetSchema: @escaping () -> SchemaProtocol,
        valueMemberSchema: @escaping () -> SchemaProtocol,
        valueTargetSchema: @escaping () -> SchemaProtocol,
        readBlock: @escaping (any ShapeDeserializer) throws -> Value,
        writeBlock: @escaping (any SmithyWriter, Value) throws -> Void
    ) {
//        self.namespace = namespace
//        self.name = name
        self.type = type
        self.keyMemberSchema = keyMemberSchema
        self.keyTargetSchema = keyTargetSchema
        self.valueMemberSchema = valueMemberSchema
        self.valueTargetSchema = valueTargetSchema
        self.readBlock = readBlock
        self.writeBlock = writeBlock
    }

    public func read(reader: any SmithyReader) throws {
        // TODO: implement
    }

    public func write(writer: any SmithyWriter) throws {
        // TODO: implement
    }
}

@_spi(SchemaBasedSerde)
public class MemberSchema<Base>: SchemaProtocol {
//    public let namespace: String
//    public let name: String
    public let type: ShapeType
    public let memberName: String?
    public let jsonName: String?
    public let xmlName: String?
    public let isRequired: Bool
    public let defaultValue: (any SmithyDocument)?

    public init(
        namespace: String = "",
        name: String = "",
        type: ShapeType,
        memberName: String? = nil,
        jsonName: String? = nil,
        xmlName: String? = nil,
        isRequired: Bool = false,
        defaultValue: SmithyDocument? = nil
    ) {
//        self.namespace = namespace
//        self.name = name
        self.type = type
        self.memberName = memberName
        self.jsonName = jsonName
        self.xmlName = xmlName
        self.isRequired = isRequired
        self.defaultValue = defaultValue
    }

    public func read(reader: any SmithyReader) throws {
        // TODO: implement
    }

    public func write(writer: any SmithyWriter) throws {
        // TODO: implement
    }
}

@_spi(SchemaBasedSerde)
public class SimpleSchema<Base>: SchemaProtocol {
//    public let namespace: String
//    public let name: String
    public let type: ShapeType
    public let memberName: String?
    public let isRequired: Bool
    public let timestampFormat: TimestampFormat?
    public let defaultValue: (any SmithyDocument)?

    public init(
        namespace: String = "",
        name: String = "",
        type: ShapeType,
        memberName: String? = nil,
        isRequired: Bool = false,
        timestampFormat: TimestampFormat? = nil,
        defaultValue: SmithyDocument? = nil
    ) {
//        self.namespace = namespace
//        self.name = name
        self.type = type
        self.memberName = memberName
        self.isRequired = isRequired
        self.timestampFormat = timestampFormat
        self.defaultValue = defaultValue
    }

    public func read(reader: any SmithyReader) throws {
        // TODO: implement
    }

    public func write(writer: any SmithyWriter) throws {
        // TODO: implement
    }
}
