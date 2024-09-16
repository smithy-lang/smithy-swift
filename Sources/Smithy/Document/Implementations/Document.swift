//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import struct Foundation.Date

/// A type-erased container for some value conforming to the `SmithyDocument` protocol.
public struct Document: SmithyDocument {
    let document: SmithyDocument

    public init(_ document: SmithyDocument) {
        self.document = document
    }
}

// Since protocol-bound values cannot conform to Self-referencing
// protocols like `Equatable`, the `Document` container provides the
// `Equatable` conformance.
extension Document: Equatable {

    public static func ==(_ lhs: Document, _ rhs: Document) -> Bool {
        isEqual(lhs.document, rhs.document)
    }
}

// All of these implementations of `SmithyDocument` methods simply delegate
// to the inner document.
public extension Document {

    var type: Smithy.ShapeType {
        document.type
    }

    func asBoolean() throws -> Bool {
        try document.asBoolean()
    }

    func asString() throws -> String {
        try document.asString()
    }

    func asList() throws -> [SmithyDocument] {
        try document.asList()
    }

    func asStringMap() throws -> [String: SmithyDocument] {
        try document.asStringMap()
    }

    func size() -> Int {
        document.size()
    }

    func asByte() throws -> Int8 {
        try document.asByte()
    }

    func asShort() throws -> Int16 {
        try document.asShort()
    }

    func asInteger() throws -> Int {
        try document.asInteger()
    }

    func asLong() throws -> Int64 {
        try document.asLong()
    }

    func asFloat() throws -> Float {
        try document.asFloat()
    }

    func asDouble() throws -> Double {
        try document.asDouble()
    }

    func asBigInteger() throws -> Int64 {
        try document.asBigInteger()
    }

    func asBigDecimal() throws -> Double {
        try document.asBigDecimal()
    }

    func asBlob() throws -> Data {
        try document.asBlob()
    }

    func asTimestamp() throws -> Date {
        try document.asTimestamp()
    }

    func getMember(_ memberName: String) throws -> SmithyDocument? {
        try document.getMember(memberName)
    }
}
