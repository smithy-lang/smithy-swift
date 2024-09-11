//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

protocol SmithyDocument {

    // "as" methods throw if the document doesn't match the requested type.
    func asBoolean() throws -> Bool
    func asString() throws -> String
    func asList() throws -> [Document]
    func asStringMap() throws -> [String: Document]

    // Get the number of list elements or map entries. Returns -1 if the
    // document is not a list or map.
    func size() -> Int

    // Throw if not numeric. Numeric accessors should automatically coerce a value
    // to the requested numeric type, but throw if the value would overflow.
    func asByte() throws -> UInt8
    func asShort() throws -> Int16
    func asInteger() throws -> Int
    func asLong() throws -> Int64
    func asFloat() throws -> Float
    func asDouble() throws -> Double

    // Protocols that don't support blob serialization like JSON should
    // automatically attempt to base64 decode a string and return it as a blob.
    func asBlob() throws -> Data

    // Protocols like JSON that don't support timestamps should automatically
    // convert values based on the timestamp format of the shape or the codec.
    func asTimestamp() throws -> Date

    // Get a member by name, taking protocol details like jsonName into account.
    func getMember(_ memberName: String) -> Document?
}
