//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Smithy.Document
@_spi(SmithyDocumentImpl) import struct Smithy.NullDocument
import struct Foundation.Data
import struct Foundation.Date

@_spi(SchemaBasedSerde)
public protocol ShapeDeserializer: SmithyReader {
    func readStructure<T: DeserializableShape>(schema: Schema<T>) throws -> T?
    func readList<T>(schema: Schema<[T]>) throws -> [T]?
    func readMap<T>(schema: Schema<[String: T]>) throws -> [String: T]?
    func readBoolean(schema: Schema<Bool>) throws -> Bool?
    func readByte(schema: Schema<Int8>) throws -> Int8?
    func readShort(schema: Schema<Int16>) throws -> Int16?
    func readInteger(schema: Schema<Int>) throws -> Int?
    func readLong(schema: Schema<Int>) throws -> Int?
    func readFloat(schema: Schema<Float>) throws -> Float?
    func readDouble(schema: Schema<Double>) throws -> Double?
    func readBigInteger(schema: Schema<Int>) throws -> Int?
    func readBigDecimal(schema: Schema<Double>) throws -> Double?
    func readString(schema: Schema<String>) throws -> String?
    func readBlob(schema: Schema<Data>) throws -> Data?
    func readTimestamp(schema: Schema<Date>) throws -> Date?
    func readDocument(schema: Schema<Document>) throws -> Document?
    func readNull(schema: SchemaProtocol) throws -> Bool?
    func readEnum<T: RawRepresentable>(schema: Schema<T>) throws -> T? where T.RawValue == String
    func readIntEnum<T: RawRepresentable>(schema: Schema<T>) throws -> T? where T.RawValue == Int
}

@_spi(SchemaBasedSerde)
public extension ShapeDeserializer {

    func readEnum<T: RawRepresentable>(schema: Schema<T>) throws -> T? where T.RawValue == String {
        guard hasContent else { return nil }
        guard let rawValue: String = try readIfPresent() else { throw ReaderError.requiredValueNotPresent }
        for memberContainer in schema.members {
            guard let resolvedEnumValue = try memberContainer.member.memberSchema.enumValue?.asString() ?? memberContainer.member.memberSchema.memberName else {
                throw ReaderError.requiredValueNotPresent
            }
            if rawValue == resolvedEnumValue {
                return T(rawValue: rawValue)
            }
        }
        return T(rawValue: "")
    }

    func readIntEnum<T: RawRepresentable>(schema: Schema<T>) throws -> T? where T.RawValue == Int {
        guard hasContent else { return nil }
        guard let rawValue: Int = try readIfPresent() else { throw ReaderError.requiredValueNotPresent }
        for memberContainer in schema.members {
            guard let resolvedEnumValue = try memberContainer.member.memberSchema.enumValue?.asInteger() else {
                throw ReaderError.requiredValueNotPresent
            }
            if rawValue == resolvedEnumValue {
                return T(rawValue: rawValue)
            }
        }
        return T(rawValue: Int.min)
    }

    func readEnumNonNull<T: RawRepresentable>(schema: Schema<T>) throws -> T where T.RawValue == String {
        guard let value: T = try readEnum(schema: schema) else {
            throw ReaderError.requiredValueNotPresent
            return T(rawValue: "")!
        }
        return value
    }

    func readIntEnumNonNull<T: RawRepresentable>(schema: Schema<T>) throws -> T where T.RawValue == Int {
        guard let value: T = try readIntEnum(schema: schema) else {
            throw ReaderError.requiredValueNotPresent
            return T(rawValue: Int.min)!
        }
        return value
    }
}

@_spi(SchemaBasedSerde)
public extension ShapeDeserializer {

    func readStructureNonNull<T: DeserializableShape>(schema: Schema<T>) throws -> T {
        guard let value = try readStructure(schema: schema) else {
            throw ReaderError.requiredValueNotPresent
        }
        return value
    }

    func readListNonNull<T>(schema: Schema<[T]>) throws -> [T] {
        guard let value = try readList(schema: schema) else {
            throw ReaderError.requiredValueNotPresent
        }
        return value
//        return try readList(schema: schema) ?? []
    }

    func readMapNonNull<T>(schema: Schema<[String: T]>) throws -> [String: T] {
        guard let value = try readMap(schema: schema) else {
            throw ReaderError.requiredValueNotPresent
        }
        return value
//        return try readMap(schema: schema) ?? [:]
    }

    func readBooleanNonNull(schema: Schema<Bool>) throws -> Bool {
        guard let value = try readBoolean(schema: schema) else {
            throw ReaderError.requiredValueNotPresent
        }
        return value
//        return try readBoolean(schema: schema) ?? false
    }

    func readByteNonNull(schema: Schema<Int8>) throws -> Int8 {
        guard let value = try readByte(schema: schema) else {
            throw ReaderError.requiredValueNotPresent
        }
        return value
//        return try readByte(schema: schema) ?? 0
    }

    func readShortNonNull(schema: Schema<Int16>) throws -> Int16 {
        guard let value = try readShort(schema: schema) else {
            throw ReaderError.requiredValueNotPresent
        }
        return value
//        return try readShort(schema: schema) ?? 0
    }

    func readIntegerNonNull(schema: Schema<Int>) throws -> Int {
        guard let value = try readInteger(schema: schema) else {
            throw ReaderError.requiredValueNotPresent
        }
        return value
//        return try readInteger(schema: schema) ?? 0
    }

    func readLongNonNull(schema: Schema<Int>) throws -> Int {
        guard let value = try readLong(schema: schema) else {
            throw ReaderError.requiredValueNotPresent
        }
        return value
//        return try readLong(schema: schema) ?? 0
    }

    func readFloatNonNull(schema: Schema<Float>) throws -> Float {
        guard let value = try readFloat(schema: schema) else {
            throw ReaderError.requiredValueNotPresent
        }
        return value
//        return try readFloat(schema: schema) ?? 0.0
    }

    func readDoubleNonNull(schema: Schema<Double>) throws -> Double {
        guard let value = try readDouble(schema: schema) else {
            throw ReaderError.requiredValueNotPresent
        }
        return value
//        return try readDouble(schema: schema) ?? 0.0
    }

    func readBigIntegerNonNull(schema: Schema<Int>) throws -> Int {
        guard let value = try readBigInteger(schema: schema) else {
            throw ReaderError.requiredValueNotPresent
        }
        return value
//        return try readBigInteger(schema: schema) ?? 0
    }

    func readBigDecimalNonNull(schema: Schema<Double>) throws -> Double {
        guard let value = try readBigDecimal(schema: schema) else {
            throw ReaderError.requiredValueNotPresent
        }
        return value
//        return try readBigDecimal(schema: schema) ?? 0.0
    }

    func readStringNonNull(schema: Schema<String>) throws -> String {
        guard let value = try readString(schema: schema) else {
            throw ReaderError.requiredValueNotPresent
        }
        return value
//        return try readString(schema: schema) ?? ""
    }

    func readBlobNonNull(schema: Schema<Data>) throws -> Data {
        guard let value = try readBlob(schema: schema) else {
            throw ReaderError.requiredValueNotPresent
        }
        return value
//        return try readBlob(schema: schema) ?? Data()
    }

    func readTimestampNonNull(schema: Schema<Date>) throws -> Date {
        guard let value = try readTimestamp(schema: schema) else {
            throw ReaderError.requiredValueNotPresent
        }
        return value
//        return try readTimestamp(schema: schema) ?? Date(timeIntervalSince1970: 0.0)
    }

    func readDocumentNonNull(schema: Schema<Document>) throws -> Document {
        guard let value = try readDocument(schema: schema) else {
            throw ReaderError.requiredValueNotPresent
        }
        return value
//        return try readDocument(schema: schema) ?? Document(NullDocument())
    }

    func readNullNonNull(schema: SchemaProtocol) throws -> Bool {
        guard let value = try readNull(schema: schema) else {
            throw ReaderError.requiredValueNotPresent
        }
        return value
//        return try readNull(schema: schema) ?? false
    }
}
