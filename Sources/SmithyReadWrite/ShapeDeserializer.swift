//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Smithy.Document
import struct Foundation.Data
import struct Foundation.Date

@_spi(SchemaBasedSerde)
public protocol ShapeDeserializer {
    func readStructure<T: DeserializableShape>(schema: StructureSchema<T>) throws -> T?
    func readList<T>(schema: ListSchema<T>) throws -> [T]?
    func readMap<T>(schema: MapSchema<T>) throws -> [String: T]?
    func readBoolean(schema: SchemaProtocol) throws -> Bool?
    func readByte(schema: SchemaProtocol) throws -> Int8?
    func readShort(schema: SchemaProtocol) throws -> Int16?
    func readInteger(schema: SchemaProtocol) throws -> Int?
    func readLong(schema: SchemaProtocol) throws -> Int?
    func readFloat(schema: SchemaProtocol) throws -> Float?
    func readDouble(schema: SchemaProtocol) throws -> Double?
    func readBigInteger(schema: SchemaProtocol) throws -> Int?
    func readBigDecimal(schema: SchemaProtocol) throws -> Float?
    func readString(schema: SchemaProtocol) throws -> String?
    func readBlob(schema: SchemaProtocol) throws -> Data?
    func readTimestamp(schema: SimpleSchema<Date>) throws -> Date?
    func readDocument(schema: SchemaProtocol) throws -> Document?
    func readNull(schema: SchemaProtocol) throws -> Bool?
}

@_spi(SchemaBasedSerde)
public extension ShapeDeserializer {

    func readEnum<T: RawRepresentable>(schema: SchemaProtocol) throws -> T? where T.RawValue == String {
        guard let rawValue = try readString(schema: schema) else { return nil }
        return T(rawValue: rawValue)
    }

    func readIntEnum<T: RawRepresentable>(schema: SchemaProtocol) throws -> T? where T.RawValue == Int {
        guard let rawValue = try readInteger(schema: schema) else { return nil }
        return T(rawValue: rawValue)
    }

    func readEnumNonNull<T: RawRepresentable>(schema: SchemaProtocol) throws -> T where T.RawValue == String {
        guard let value: T = try readEnum(schema: schema) else {
            throw ReaderError.requiredValueNotPresent
        }
        return value
    }

    func readIntEnumNonNull<T: RawRepresentable>(schema: SchemaProtocol) throws -> T where T.RawValue == Int {
        guard let value: T = try readIntEnum(schema: schema) else {
            throw ReaderError.requiredValueNotPresent
        }
        return value
    }
}

@_spi(SchemaBasedSerde)
public extension ShapeDeserializer {

    func readStructureNonNull<T: DeserializableShape>(schema: StructureSchema<T>) throws -> T {
        guard let value = try readStructure(schema: schema) else {
            throw ReaderError.requiredValueNotPresent
        }
        return value
    }
    func readListNonNull<T>(schema: ListSchema<T>) throws -> [T] {
        guard let value = try readList(schema: schema) else {
            throw ReaderError.requiredValueNotPresent
        }
        return value
    }

    func readMapNonNull<T>(schema: MapSchema<T>) throws -> [String: T] {
        guard let value = try readMap(schema: schema) else {
            throw ReaderError.requiredValueNotPresent
        }
        return value
    }

    func readBooleanNonNull(schema: SimpleSchema<Bool>) throws -> Bool {
        guard let value = try readBoolean(schema: schema) else {
            throw ReaderError.requiredValueNotPresent
        }
        return value
    }

    func readByteNonNull(schema: SimpleSchema<Int8>) throws -> Int8 {
        guard let value = try readByte(schema: schema) else {
            throw ReaderError.requiredValueNotPresent
        }
        return value
    }

    func readShortNonNull(schema: SimpleSchema<Int16>) throws -> Int16 {
        guard let value = try readShort(schema: schema) else {
            throw ReaderError.requiredValueNotPresent
        }
        return value
    }

    func readIntegerNonNull(schema: SimpleSchema<Int>) throws -> Int {
        guard let value = try readInteger(schema: schema) else {
            throw ReaderError.requiredValueNotPresent
        }
        return value
    }

    func readLongNonNull(schema: SimpleSchema<Int>) throws -> Int {
        guard let value = try readLong(schema: schema) else {
            throw ReaderError.requiredValueNotPresent
        }
        return value
    }

    func readFloatNonNull(schema: SimpleSchema<Float>) throws -> Float {
        guard let value = try readFloat(schema: schema) else {
            throw ReaderError.requiredValueNotPresent
        }
        return value
    }

    func readDoubleNonNull(schema: SimpleSchema<Double>) throws -> Double {
        guard let value = try readDouble(schema: schema) else {
            throw ReaderError.requiredValueNotPresent
        }
        return value
    }

    func readBigIntegerNonNull(schema: SimpleSchema<Int>) throws -> Int {
        guard let value = try readBigInteger(schema: schema) else {
            throw ReaderError.requiredValueNotPresent
        }
        return value
    }

    func readBigDecimalNonNull(schema: SimpleSchema<Float>) throws -> Float {
        guard let value = try readBigDecimal(schema: schema) else {
            throw ReaderError.requiredValueNotPresent
        }
        return value
    }

    func readStringNonNull(schema: SimpleSchema<String>) throws -> String {
        guard let value = try readString(schema: schema) else {
            throw ReaderError.requiredValueNotPresent
        }
        return value
    }

    func readBlobNonNull(schema: SimpleSchema<Data>) throws -> Data {
        guard let value = try readBlob(schema: schema) else {
            throw ReaderError.requiredValueNotPresent
        }
        return value
    }

    func readTimestampNonNull(schema: SimpleSchema<Date>) throws -> Date {
        guard let value = try readTimestamp(schema: schema) else {
            throw ReaderError.requiredValueNotPresent
        }
        return value
    }

    func readDocumentNonNull(schema: SimpleSchema<Document>) throws -> Document {
        guard let value = try readDocument(schema: schema) else {
            throw ReaderError.requiredValueNotPresent
        }
        return value
    }

    func readNullNonNull(schema: SimpleSchema<Void>) throws -> Bool {
        guard let value = try readNull(schema: schema) else {
            throw ReaderError.requiredValueNotPresent
        }
        return value
    }
}
