//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import struct Foundation.Date

public struct DocumentContainer: Document {
    public var type: Smithy.ShapeType { document.type }
    let document: any Document

    public init(document: any Document) {
        self.document = document
    }
}

extension DocumentContainer: Equatable {

    public static func ==(_ lhs: DocumentContainer, _ rhs: DocumentContainer) -> Bool {
        isEqual(lhs.document, rhs.document)
    }
}

// All of these implementations simply delegate to the inner document.
public extension DocumentContainer {

    func asBoolean() throws -> Bool {
        try document.asBoolean()
    }

    func asString() throws -> String {
        try document.asString()
    }

    func asList() throws -> [any Document] {
        try document.asList()
    }

    func asStringMap() throws -> [String: any Document] {
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

    func getMember(_ memberName: String) throws -> (any Document)? {
        try document.getMember(memberName)
    }
}
