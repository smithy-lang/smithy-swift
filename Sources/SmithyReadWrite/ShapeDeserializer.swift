//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class Smithy.Schema
import struct Smithy.Document
@_spi(SmithyDocumentImpl) import struct Smithy.NullDocument
import struct Foundation.Data
import struct Foundation.Date

@_spi(SmithyReadWrite)
public protocol ShapeDeserializer: SmithyReader {
    func readStructure<T: SerializableStruct>(schema: Schema) throws -> T?
    func readList<T>(schema: Schema) throws -> [T]?
    func readMap<T>(schema: Schema) throws -> [String: T]?
    func readBoolean(schema: Schema) throws -> Bool?
    func readByte(schema: Schema) throws -> Int8?
    func readShort(schema: Schema) throws -> Int16?
    func readInteger(schema: Schema) throws -> Int?
    func readLong(schema: Schema) throws -> Int?
    func readFloat(schema: Schema) throws -> Float?
    func readDouble(schema: Schema) throws -> Double?
    func readBigInteger(schema: Schema) throws -> Int64?
    func readBigDecimal(schema: Schema) throws -> Double?
    func readString(schema: Schema) throws -> String?
    func readBlob(schema: Schema) throws -> Data?
    func readTimestamp(schema: Schema) throws -> Date?
    func readDocument(schema: Schema) throws -> Document?
    func readNull(schema: Schema) throws -> Bool?
    func readEnum<T: RawRepresentable>(schema: Schema) throws -> T? where T.RawValue == String
    func readIntEnum<T: RawRepresentable>(schema: Schema) throws -> T? where T.RawValue == Int
}

@_spi(SmithyReadWrite)
public extension ShapeDeserializer {

    func readEnumNonNull<T: RawRepresentable>(schema: Schema) throws -> T where T.RawValue == String {
        guard let value: T = try readEnum(schema: schema) else {
            throw ReaderError.requiredValueNotPresent
        }
        return value
    }

    func readIntEnumNonNull<T: RawRepresentable>(schema: Schema) throws -> T where T.RawValue == Int {
        guard let value: T = try readIntEnum(schema: schema) else {
            throw ReaderError.requiredValueNotPresent
        }
        return value
    }
}

@_spi(SmithyReadWrite)
public extension ShapeDeserializer {

    func readStructureNonNull<T>(schema: Schema) throws -> T {
        guard let value: T = try readStructure(schema: schema) else {
//            guard let factory = schema.factory else {
//                throw SmithyReadWrite.ReaderError.invalidSchema("Missing factory for structure or union: \(schema.id)")
//            }
//            if schema.isRequired { return factory() }
            throw ReaderError.requiredValueNotPresent
        }
        return value
    }

    func readListNonNull<T>(schema: Schema) throws -> [T] {
        guard let value: [T] = try readList(schema: schema) else {
            if schema.isRequired { return [] }
            throw ReaderError.requiredValueNotPresent
        }
        return value
    }

    func readMapNonNull<T>(schema: Schema) throws -> [String: T] {
        guard let value: [String: T] = try readMap(schema: schema) else {
            if schema.isRequired { return [:] }
            throw ReaderError.requiredValueNotPresent
        }
        return value
    }

    func readBooleanNonNull(schema: Schema) throws -> Bool {
        guard let value = try readBoolean(schema: schema) else {
            if schema.isRequired { return false }
            throw ReaderError.requiredValueNotPresent
        }
        return value
    }

    func readByteNonNull(schema: Schema) throws -> Int8 {
        guard let value = try readByte(schema: schema) else {
            if schema.isRequired { return 0 }
            throw ReaderError.requiredValueNotPresent
        }
        return value
    }

    func readShortNonNull(schema: Schema) throws -> Int16 {
        guard let value = try readShort(schema: schema) else {
            if schema.isRequired { return 0 }
            throw ReaderError.requiredValueNotPresent
        }
        return value
    }

    func readIntegerNonNull(schema: Schema) throws -> Int {
        guard let value = try readInteger(schema: schema) else {
            if schema.isRequired { return 0 }
            throw ReaderError.requiredValueNotPresent
        }
        return value
    }

    func readLongNonNull(schema: Schema) throws -> Int {
        guard let value = try readLong(schema: schema) else {
            if schema.isRequired { return 0 }
            throw ReaderError.requiredValueNotPresent
        }
        return value
    }

    func readFloatNonNull(schema: Schema) throws -> Float {
        guard let value = try readFloat(schema: schema) else {
            if schema.isRequired { return 0.0 }
            throw ReaderError.requiredValueNotPresent
        }
        return value
    }

    func readDoubleNonNull(schema: Schema) throws -> Double {
        guard let value = try readDouble(schema: schema) else {
            if schema.isRequired { return 0.0 }
            throw ReaderError.requiredValueNotPresent
        }
        return value
    }

    func readBigIntegerNonNull(schema: Schema) throws -> Int64 {
        guard let value = try readBigInteger(schema: schema) else {
            if schema.isRequired { return 0 }
            throw ReaderError.requiredValueNotPresent
        }
        return value
    }

    func readBigDecimalNonNull(schema: Schema) throws -> Double {
        guard let value = try readBigDecimal(schema: schema) else {
            if schema.isRequired { return 0.0 }
            throw ReaderError.requiredValueNotPresent
        }
        return value
    }

    func readStringNonNull(schema: Schema) throws -> String {
        guard let value = try readString(schema: schema) else {
            if schema.isRequired { return "" }
            throw ReaderError.requiredValueNotPresent
        }
        return value
    }

    func readBlobNonNull(schema: Schema) throws -> Data {
        guard let value = try readBlob(schema: schema) else {
            if schema.isRequired { return Data() }
            throw ReaderError.requiredValueNotPresent
        }
        return value
    }

    func readTimestampNonNull(schema: Schema) throws -> Date {
        guard let value = try readTimestamp(schema: schema) else {
            if schema.isRequired { return Date(timeIntervalSince1970: 0.0) }
            throw ReaderError.requiredValueNotPresent
        }
        return value
    }

    func readDocumentNonNull(schema: Schema) throws -> Document {
        guard let value = try readDocument(schema: schema) else {
            if schema.isRequired { return Document(NullDocument()) }
            throw ReaderError.requiredValueNotPresent
        }
        return value
    }

    func readNullNonNull(schema: Schema) throws -> Bool {
        guard let value = try readNull(schema: schema) else {
            if schema.isRequired { return false }
            throw ReaderError.requiredValueNotPresent
        }
        return value
    }
}
