//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import struct Foundation.Date

public protocol SmithyDocument: Sendable {

    /// The Smithy type corresponding to the data stored in this document.
    var type: ShapeType { get }

    // "as" methods throw if the document doesn't match the requested type.
    func asBoolean() throws -> Bool
    func asString() throws -> String
    func asList() throws -> [SmithyDocument]
    func asStringMap() throws -> [String: SmithyDocument]

    // Get the number of list elements or map entries. Returns -1 if the
    // document is not a list or map.
    func size() -> Int

    // Throw if not numeric. Numeric accessors should automatically coerce a value
    // to the requested numeric type, but throw if the value would overflow.
    func asByte() throws -> Int8
    func asShort() throws -> Int16
    func asInteger() throws -> Int
    func asLong() throws -> Int64
    func asFloat() throws -> Float
    func asDouble() throws -> Double
    func asBigInteger() throws -> Int64
    func asBigDecimal() throws -> Double

    // Protocols that don't support blob serialization like JSON should
    // automatically attempt to base64 decode a string and return it as a blob.
    func asBlob() throws -> Data

    // Protocols like JSON that don't support timestamps should automatically
    // convert values based on the timestamp format of the shape or the codec.
    func asTimestamp() throws -> Date

    // Get a member by name, taking protocol details like jsonName into account.
    func getMember(_ memberName: String) throws -> SmithyDocument?
}

// Default implementations for a Document that either throw or (for size())
// return a default value.
public extension SmithyDocument {

    func asBoolean() throws -> Bool {
        throw DocumentError.typeMismatch("Expected boolean, got \(self)")
    }

    func asString() throws -> String {
        throw DocumentError.typeMismatch("Expected string, got \(self)")
    }

    func asList() throws -> [SmithyDocument] {
        throw DocumentError.typeMismatch("Expected list, got \(self)")
    }

    func asStringMap() throws -> [String: SmithyDocument] {
        throw DocumentError.typeMismatch("Expected map, got \(self)")
    }

    func size() -> Int {
        -1
    }

    func asByte() throws -> Int8 {
        throw DocumentError.typeMismatch("Expected byte, got \(self)")
    }

    func asShort() throws -> Int16 {
        throw DocumentError.typeMismatch("Expected short, got \(self)")
    }

    func asInteger() throws -> Int {
        throw DocumentError.typeMismatch("Expected int, got \(self)")
    }

    func asLong() throws -> Int64 {
        throw DocumentError.typeMismatch("Expected long, got \(self)")
    }

    func asFloat() throws -> Float {
        throw DocumentError.typeMismatch("Expected float, got \(self)")
    }

    func asDouble() throws -> Double {
        throw DocumentError.typeMismatch("Expected double, got \(self)")
    }

    func asBigInteger() throws -> Int64 {
        throw DocumentError.typeMismatch("Expected BigInteger, got \(self)")
    }

    func asBigDecimal() throws -> Double {
        throw DocumentError.typeMismatch("Expected BigDecimal, got \(self)")
    }

    func asBlob() throws -> Data {
        throw DocumentError.typeMismatch("Expected blob, got \(self)")
    }

    func asTimestamp() throws -> Date {
        throw DocumentError.typeMismatch("Expected timestamp, got \(self)")
    }

    func getMember(_ memberName: String) throws -> SmithyDocument? {
        throw DocumentError.typeMismatch("Expected a map, structure, or union document, got \(self)")
    }
}

extension SmithyDocument {

    /// Compares two `SmithyDocument`-conforming values, checking for equality.
    ///
    /// Two `SmithyDocument`s are equal if they have the same type and equal values.
    ///
    /// Two Smithy `list` documents are equal if they have equal documents at every index.
    ///
    /// Two Smithy `map` documents are equal if they have the same set of keys, and equal values for every key.
    ///
    /// - note: Because `SmithyDocument` is a protocol, it cannot conform to `Equatable`; the type-erased
    /// container type ``Document`` is used to provide Smithy documents with equatability.
    /// - Parameters:
    ///   - lhs: The first `SmithyDocument` to compare.
    ///   - rhs: The second `SmithyDocument` to compare.
    /// - Returns: `true` if the two `SmithyDocument`s are equal, `false` otherwise.
    public static func isEqual(_ lhs: SmithyDocument, _ rhs: SmithyDocument) -> Bool {
        switch (lhs.type, rhs.type) {
        case (.blob, .blob):
            return (try? lhs.asBlob() == rhs.asBlob()) ?? false
        case (.boolean, .boolean):
            return (try? lhs.asBoolean() == rhs.asBoolean()) ?? false
        case (.string, .string):
            return (try? lhs.asString() == rhs.asString()) ?? false
        case (.timestamp, .timestamp):
            return (try? lhs.asTimestamp() == rhs.asTimestamp()) ?? false
        case (.byte, .byte):
            return (try? lhs.asByte() == rhs.asByte()) ?? false
        case (.short, .short):
            return (try? lhs.asShort() == rhs.asShort()) ?? false
        case (.integer, .integer):
            return (try? lhs.asInteger() == rhs.asInteger()) ?? false
        case (.long, .long):
            return (try? lhs.asLong() == rhs.asLong()) ?? false
        case (.float, .float):
            return (try? lhs.asFloat() == rhs.asFloat()) ?? false
        case (.double, .double):
            return (try? lhs.asDouble() == rhs.asDouble()) ?? false
        case (.bigDecimal, .bigDecimal):
            return (try? lhs.asBigDecimal() == rhs.asBigDecimal()) ?? false
        case (.bigInteger, .bigInteger):
            return (try? lhs.asBigInteger() == rhs.asBigInteger()) ?? false
        case (.list, .list):
            guard let lhsList = try? lhs.asList(), let rhsList = try? rhs.asList() else { return false }
            guard lhsList.count == rhsList.count else { return false }
            return zip(lhsList, rhsList).allSatisfy { isEqual($0.0, $0.1) }
        case (.map, .map):
            guard let lhsMap = try? lhs.asStringMap(), let rhsMap = try? rhs.asStringMap() else { return false }
            guard lhsMap.count == rhsMap.count else { return false }
            return lhsMap.keys.allSatisfy { key in
                guard let leftValue = lhsMap[key], let rightValue = rhsMap[key] else { return false }
                return isEqual(leftValue, rightValue)
            }
        case (.structure, .structure):
            return true  // structure type is currently only used for null values
        default:
            return false
        }
    }
}
