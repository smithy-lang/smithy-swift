//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import struct Foundation.Date
import class Foundation.DateFormatter
import struct Foundation.Locale

extension Document: SmithyDocument {
    func asBoolean() throws -> Bool {
        guard case .boolean(let value) = self else {
            throw SmithyDocumentError.typeMismatch("Expected boolean, got \(self)")
        }
        return value
    }

    func asString() throws -> String {
        guard case .string(let value) = self else {
            throw SmithyDocumentError.typeMismatch("Expected string, got \(self)")
        }
        return value
    }

    func asList() throws -> [Document] {
        guard case .list(let value) = self else {
            throw SmithyDocumentError.typeMismatch("Expected list, got \(self)")
        }
        return value
    }

    func asStringMap() throws -> [String: Document] {
        guard case .map(let value) = self else {
            throw SmithyDocumentError.typeMismatch("Expected map, got \(self)")
        }
        return value
    }

    func size() -> Int {
        switch self {
        case .list(let array): return array.count
        case .map(let dict): return dict.count
        default: return -1
        }
    }

    func asByte() throws -> Int8 {
        guard case .byte(let value) = self else {
            throw SmithyDocumentError.typeMismatch("\(self) is not of type byte")
        }

        guard let byteValue = Int8(exactly: value) else {
            throw SmithyDocumentError.numberOverflow("Value \(value) cannot fit in Int8")
        }

        return byteValue
    }

    func asShort() throws -> Int16 {
        guard case .short(let value) = self else {
            throw SmithyDocumentError.typeMismatch("\(self) is not of type short")
        }

        guard let shortValue = Int16(exactly: value) else {
            throw SmithyDocumentError.numberOverflow("Value \(value) cannot fit in Int16")
        }

        return shortValue
    }

    func asInteger() throws -> Int {
        guard case .integer(let value) = self else {
            throw SmithyDocumentError.typeMismatch("\(self) is not of type integer")
        }

        guard let integerValue = Int(exactly: value) else {
            throw SmithyDocumentError.numberOverflow("Value \(value) cannot fit in Int")
        }

        return integerValue
    }

    func asLong() throws -> Int64 {
        guard case .long(let value) = self else {
            throw SmithyDocumentError.typeMismatch("\(self) is not of type long")
        }

        guard let longValue = Int64(exactly: value) else {
            throw SmithyDocumentError.numberOverflow("Value \(value) cannot fit in Int64")
        }

        return longValue
    }

    func asFloat() throws -> Float {
        guard case .float(let value) = self else {
            throw SmithyDocumentError.typeMismatch("\(self) is not of type float")
        }

        guard let floatValue = Float(exactly: value) else {
            throw SmithyDocumentError.numberOverflow("Value \(value) cannot fit in Float")
        }

        return floatValue
    }

    func asDouble() throws -> Double {
        guard case .double(let value) = self else {
            throw SmithyDocumentError.typeMismatch("\(self) is not of type double")
        }

        guard let doubleValue = Double(exactly: value) else {
            throw SmithyDocumentError.numberOverflow("Value \(value) cannot fit in Double")
        }

        return doubleValue
    }

    func asBigInteger() throws -> Int64 {
        return try asLong() // BigInteger is not supported at this time
    }

    func asBigDecimal() throws -> Double {
        return try asDouble() // BigDecimal is not supported at this time
    }

    func asBlob() throws -> Data {
        switch self {
        case .blob(let data):
            return data
        case .string(let str):
            guard let data = Data(base64Encoded: str) else {
                throw SmithyDocumentError.invalidBase64("Invalid base64 string")
            }
            return data
        default:
            throw SmithyDocumentError.typeMismatch("Expected blob or base64 string, got \(self)")
        }
    }

    func asTimestamp() throws -> Date {
        switch self {
        case .timestamp(let date):
            return date
        case .string(let str):
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            guard let date = formatter.date(from: str) else {
                throw SmithyDocumentError.invalidDateFormat("Invalid date format: \(str)")
            }
            return date
        default:
            throw SmithyDocumentError.typeMismatch("Expected timestamp or date string, got \(self)")
        }
    }

    func getMember(_ memberName: String) -> Document? {
        self[memberName]
    }
}
