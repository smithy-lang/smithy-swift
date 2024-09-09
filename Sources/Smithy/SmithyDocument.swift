//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

protocol SmithyDocument {

    // "as" methods throw if the document doesn't match the requested type.
    func asBoolean() -> Bool
    func asString() -> String
    func asList() -> [Document]
    func asStringMap() -> [String: Document]

    // Get the number of list elements or map entries. Returns -1 if the
    // document is not a list or map.
    func size() -> Int

    // Throw if not numeric. Numeric accessors should automatically coerce a value
    // to the requested numeric type, but throw if the value would overflow.
    func asByte() -> UInt8
    func asShort() -> Int16
    func asInteger() -> Int
    func asLong() -> Int64
    func asFloat() -> Float
    func asDouble() -> Double

    // Protocols that don't support blob serialization like JSON should
    // automatically attempt to base64 decode a string and return it as a blob.
    func asBlob() -> Data

    // Protocols like JSON that don't support timestamps should automatically
    // convert values based on the timestamp format of the shape or the codec.
    func asTimestamp() -> Date

    // Get a member by name, taking protocol details like jsonName into account.
    func getMember(_ memberName: String) -> Document?
}
