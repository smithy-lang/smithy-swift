//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import struct Foundation.Date
import struct Smithy.Document
import struct Smithy.HttpHeaderTrait
import struct Smithy.HttpPayloadTrait
import struct Smithy.HttpPrefixHeadersTrait
import struct Smithy.HttpResponseCodeTrait
import struct Smithy.Schema
import struct Smithy.TimestampFormatTrait
import struct Smithy.XmlAttributeTrait
import struct Smithy.XmlFlattenedTrait
import struct Smithy.XmlNameTrait
import class SmithyHTTPAPI.HTTPResponse
import protocol SmithySerialization.DeserializableStruct
import typealias SmithySerialization.ReadStructConsumer
import typealias SmithySerialization.ReadValueConsumer
import struct SmithySerialization.SerializerError
import protocol SmithySerialization.ShapeDeserializer
@_spi(SmithyTimestamps) import enum SmithyTimestamps.TimestampFormat
@_spi(SmithyTimestamps) import struct SmithyTimestamps.TimestampFormatter
@_spi(SmithyReadWrite) import struct SmithyXML.NodeInfo
@_spi(SmithyReadWrite) import class SmithyXML.Reader

public struct Deserializer: ShapeDeserializer {
    let reader: Reader
    let httpResponse: HTTPResponse?
    let rawBodyData: Data?
    /// Set to true when this Deserializer's Reader holds a list of values synthesized from an
    /// HTTP header (each Reader child wraps one comma-split element).  In that case, `readList`
    /// should enumerate `reader.children` directly without filtering by XML element name.
    let isHeaderList: Bool
    /// Set to true when this Deserializer's Reader holds a value from an HTTP header.
    /// Changes the default timestamp format from .dateTime (XML) to .httpDate (Smithy HTTP spec).
    let isFromHttpHeader: Bool

    public init(data: Data) throws {
        self.httpResponse = nil
        self.rawBodyData = nil
        self.isHeaderList = false
        self.isFromHttpHeader = false
        if data.isEmpty {
            self.reader = Reader()
        } else {
            self.reader = try Reader.from(data: data)
        }
    }

    init(
        reader: Reader,
        httpResponse: HTTPResponse? = nil,
        rawBodyData: Data? = nil,
        isHeaderList: Bool = false,
        isFromHttpHeader: Bool = false
    ) {
        self.reader = reader
        self.httpResponse = httpResponse
        self.rawBodyData = rawBodyData
        self.isHeaderList = isHeaderList
        self.isFromHttpHeader = isFromHttpHeader
    }

    init(httpResponse: HTTPResponse, bodyData: Data) throws {
        self.httpResponse = httpResponse
        self.rawBodyData = bodyData
        self.isHeaderList = false
        self.isFromHttpHeader = false
        if bodyData.isEmpty {
            self.reader = Reader()
        } else {
            // Non-XML bodies (raw blob/string @httpPayload) would fail to parse here;
            // in that case we still need a Reader, so fall back to empty.
            self.reader = (try? Reader.from(data: bodyData)) ?? Reader()
        }
    }

    private func targetSchema(_ schema: Schema) -> Schema {
        schema.target ?? schema
    }

    public func readStruct<T: DeserializableStruct>(_ schema: Schema, _ value: inout T) throws {
        let structSchema: Schema
        switch schema.type {
        case .structure, .union:
            structSchema = schema
        case .member:
            guard let target = schema.target else {
                throw XMLDeserializerError("Expected non-nil target on \(schema)")
            }
            structSchema = target
        default:
            throw XMLDeserializerError("unexpected schema type \(schema.type) used with readStruct")
        }

        for member in structSchema.members {
            if let memberDeserializer = try httpBindingDeserializer(for: member) {
                do {
                    try T.readConsumer(member, &value, memberDeserializer)
                } catch is DecodedNull {
                    // skip null
                }
                continue
            }
            let elementName = xmlElementName(for: member)
            let isAttribute = member.hasTrait(XmlAttributeTrait.self)
            let childReader: Reader
            if isAttribute {
                childReader = reader[NodeInfo(elementName, location: .attribute)]
            } else if reader.nodeInfo.name == elementName && reader.hasContent && reader.children.isEmpty {
                // Unwrapped output: the reader itself IS the member value (e.g. @s3UnwrappedXmlOutput leaf)
                childReader = reader
            } else {
                childReader = reader[NodeInfo(elementName)]
            }
            guard childReader.hasContent || !childReader.children.isEmpty else { continue }
            do {
                let memberDeserializer = Deserializer(reader: childReader)
                try T.readConsumer(member, &value, memberDeserializer)
            } catch is DecodedNull {
                // skip null
            }
        }
    }

    /// If `member` has an HTTP binding trait (httpHeader, httpPrefixHeaders, httpResponseCode, httpPayload)
    /// returns a Deserializer backed by the appropriate part of the HTTP response rather than the XML body.
    /// Returns nil for normal body-bound members (the XML path should be used).
    private func httpBindingDeserializer(for member: Schema) throws -> Deserializer? {
        guard let httpResponse else { return nil }

        if let headerTrait = try member.getTrait(HttpHeaderTrait.self) {
            guard let headerValue = httpResponse.headers.value(for: headerTrait.value) else { return nil }
            // For list-typed headers, split comma-separated values into children.
            if member.target?.type == .list || member.type == .list {
                let memberTarget = member.target?.member.target ?? member.target?.member
                let isTimestamp = memberTarget?.type == .timestamp
                let listReader = Reader()
                for part in splitHeaderList(headerValue, isTimestamp: isTimestamp) {
                    listReader.addChild(Reader(content: part))
                }
                return Deserializer(reader: listReader, isHeaderList: true, isFromHttpHeader: true)
            }
            return Deserializer(reader: Reader(content: headerValue), isFromHttpHeader: true)
        }

        if let prefixTrait = try member.getTrait(HttpPrefixHeadersTrait.self) {
            let prefix = prefixTrait.value
            let mapReader = Reader()
            let lowerPrefix = prefix.lowercased()
            for (name, values) in httpResponse.headers.dictionary where name.lowercased().hasPrefix(lowerPrefix) {
                let key = String(name.dropFirst(prefix.count))
                let entry = Reader(nodeInfo: "entry", content: nil)
                entry.addChild(Reader(nodeInfo: "key", content: key))
                entry.addChild(Reader(nodeInfo: "value", content: values.joined(separator: ", ")))
                mapReader.addChild(entry)
            }
            return Deserializer(reader: mapReader, isFromHttpHeader: true)
        }

        if member.hasTrait(HttpResponseCodeTrait.self) {
            return Deserializer(reader: Reader(content: String(httpResponse.statusCode.rawValue)))
        }

        if member.hasTrait(HttpPayloadTrait.self) {
            let targetType = member.target?.type ?? member.type
            switch targetType {
            case .structure, .union:
                // Structure payload: the entire body is the payload struct. Use the root reader.
                // If the body is empty, return nil so the member stays nil.
                guard reader.hasContent || !reader.children.isEmpty else { return nil }
                return Deserializer(reader: reader, httpResponse: httpResponse, rawBodyData: rawBodyData)
            case .blob:
                // Only return a deserializer if there's actual body data.
                guard let rawBodyData, !rawBodyData.isEmpty else { return nil }
                // Reader.readIfPresent() for Data expects base64. For a raw blob payload we need
                // the bytes as-is; stash them so readBlob can return them directly.
                return Deserializer(reader: Reader(), httpResponse: httpResponse, rawBodyData: rawBodyData)
            case .string, .enum:
                guard let rawBodyData, !rawBodyData.isEmpty,
                      let str = String(data: rawBodyData, encoding: .utf8) else { return nil }
                return Deserializer(reader: Reader(content: str))
            default:
                return nil
            }
        }

        return nil
    }

    /// Splits a comma-separated HTTP header list value per RFC 7230, respecting quoted strings
    /// and HTTP date values (which contain a comma, e.g. "Mon, 16 Dec 2019 23:48:18 GMT").
    private func splitHeaderList(_ value: String, isTimestamp: Bool = false) -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false
        for ch in value {
            if ch == "\"" { inQuotes.toggle(); current.append(ch); continue }
            if ch == "," && !inQuotes {
                let trimmed = current.trimmingCharacters(in: .whitespaces)
                // HTTP dates have the form "DDD, DD MMM YYYY HH:MM:SS GMT".
                // The day-of-week abbreviation (3 letters) is followed by a comma.
                // Detect this: if the accumulated part is exactly 3 alpha chars, it's a partial date.
                if isTimestamp && trimmed.count == 3 && trimmed.allSatisfy(\.isLetter) {
                    current.append(ch)
                    continue
                }
                result.append(trimmed)
                current = ""
                continue
            }
            current.append(ch)
        }
        if !current.isEmpty {
            result.append(current.trimmingCharacters(in: .whitespaces))
        }
        return result
    }

    public func readList<E>(_ schema: Schema, _ consumer: ReadValueConsumer<E>) throws -> [E] {
        if isHeaderList {
            return try reader.children.map { try consumer(Deserializer(reader: $0, isFromHttpHeader: true)) }
        }
        let isFlattened = schema.hasTrait(XmlFlattenedTrait.self)
        var list = [E]()

        if isFlattened {
            let elementName = xmlElementName(for: schema)
            let siblings = (reader.parent?.children ?? [reader]).filter {
                $0.nodeInfo.name == elementName
            }
            guard !siblings.isEmpty else { return list }
            for sibling in siblings {
                let element = try consumer(Deserializer(reader: sibling))
                list.append(element)
            }
        } else {
            let memberSchema = targetSchema(schema).member
            let memberName = xmlElementName(for: memberSchema)
            let members = reader.children.filter { $0.nodeInfo.name == memberName }
            for member in members {
                let element = try consumer(Deserializer(reader: member))
                list.append(element)
            }
        }
        return list
    }

    public func readMap<V>(_ schema: Schema, _ consumer: ReadValueConsumer<V>) throws -> [String: V] {
        let isFlattened = schema.hasTrait(XmlFlattenedTrait.self)
        let mapSchema = targetSchema(schema)
        let keyName = xmlElementName(for: mapSchema.key)
        let valueName = xmlElementName(for: mapSchema.value)
        var map = [String: V]()

        let entries: [Reader]
        if isFlattened {
            let elementName = xmlElementName(for: schema)
            entries = (reader.parent?.children ?? []).filter { $0.nodeInfo.name == elementName }
        } else {
            entries = reader.children.filter { $0.nodeInfo.name == "entry" }
        }

        for entry in entries {
            let keyReader = entry[NodeInfo(keyName)]
            guard let key: String = try keyReader.readIfPresent() else { continue }
            let valueReader = entry[NodeInfo(valueName)]
            let value = try consumer(Deserializer(reader: valueReader))
            map[key] = value
        }
        return map
    }

    public func readBoolean(_ schema: Schema) throws -> Bool {
        guard let value: Bool = try reader.readIfPresent() else {
            throw XMLDeserializerError("Expected boolean for \(schema.id)")
        }
        return value
    }

    public func readByte(_ schema: Schema) throws -> Int8 {
        guard let value: Int8 = try reader.readIfPresent() else {
            throw XMLDeserializerError("Expected Int8 for \(schema.id)")
        }
        return value
    }

    public func readShort(_ schema: Schema) throws -> Int16 {
        guard let value: Int16 = try reader.readIfPresent() else {
            throw XMLDeserializerError("Expected Int16 for \(schema.id)")
        }
        return value
    }

    public func readInteger(_ schema: Schema) throws -> Int {
        guard let value: Int = try reader.readIfPresent() else {
            throw XMLDeserializerError("Expected Int for \(schema.id)")
        }
        return value
    }

    public func readLong(_ schema: Schema) throws -> Int {
        guard let value: Int = try reader.readIfPresent() else {
            throw XMLDeserializerError("Expected Int (long) for \(schema.id)")
        }
        return value
    }

    public func readFloat(_ schema: Schema) throws -> Float {
        guard let value: Float = try reader.readIfPresent() else {
            throw XMLDeserializerError("Expected Float for \(schema.id)")
        }
        return value
    }

    public func readDouble(_ schema: Schema) throws -> Double {
        guard let value: Double = try reader.readIfPresent() else {
            throw XMLDeserializerError("Expected Double for \(schema.id)")
        }
        return value
    }

    public func readBigInteger(_ schema: Schema) throws -> Int64 {
        guard let str: String = try reader.readIfPresent(), let value = Int64(str) else {
            throw XMLDeserializerError("Expected Int64 for \(schema.id)")
        }
        return value
    }

    public func readBigDecimal(_ schema: Schema) throws -> Double {
        try readDouble(schema)
    }

    public func readString(_ schema: Schema) throws -> String {
        guard let value: String = try reader.readIfPresent() else {
            throw XMLDeserializerError("Expected String for \(schema.id)")
        }
        return value
    }

    public func readBlob(_ schema: Schema) throws -> Data {
        if let rawBodyData { return rawBodyData }
        guard let value: Data = try reader.readIfPresent() else {
            throw XMLDeserializerError("Expected blob for \(schema.id)")
        }
        return value
    }

    public func readTimestamp(_ schema: Schema) throws -> Date {
        let format: TimestampFormat
        if (try? schema.getTrait(TimestampFormatTrait.self)) != nil {
            format = resolveTimestampFormat(schema)
        } else {
            format = isFromHttpHeader ? .httpDate : .dateTime
        }
        guard let value: Date = try reader.readTimestampIfPresent(format: format) else {
            throw XMLDeserializerError("Expected timestamp for \(schema.id)")
        }
        return value
    }

    public func readDocument(_ schema: Schema) throws -> Document {
        throw SerializerError("Document type not supported in XML")
    }

    public func readNull<T>(_ schema: Schema) throws -> T? {
        return nil
    }

    public func isNull() throws -> Bool {
        !reader.hasContent && reader.children.isEmpty
    }

    public var containerSize: Int { reader.children.count }

    private func xmlElementName(for schema: Schema) -> String {
        (try? schema.getTrait(XmlNameTrait.self))?.value ?? schema.memberName ?? schema.id.member ?? schema.id.name
    }
}

struct XMLDeserializerError: Error {
    let localizedDescription: String
    init(_ localizedDescription: String) {
        self.localizedDescription = localizedDescription
    }
}

struct DecodedNull: Error {}
