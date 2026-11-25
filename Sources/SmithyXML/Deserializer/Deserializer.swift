//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import struct Foundation.Date
@_spi(SchemaBasedSerde)
import class Smithy.Schema
import protocol Smithy.SmithyDocument
@_spi(SchemaBasedSerde)
import class Smithy.TimestampFormatTrait
@_spi(SchemaBasedSerde)
import class Smithy.XMLNameTrait
@_spi(SchemaBasedSerde)
import class SmithySerialization.DefaultValueDeserializer
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.DeserializableStruct
@_spi(SchemaBasedSerde)
import typealias SmithySerialization.ReadValueConsumer
import struct SmithySerialization.SerializerError
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.ShapeDeserializer
@_spi(SmithyTimestamps) import struct SmithyTimestamps.TimestampFormatter

/// A shape deserializer for the XML used by the Smithy `restXml`, `awsQuery`, and `ec2Query` protocols.
///
/// The XML is read as it is parsed by the libxml2 SAX parser, directly into the shapes being deserialized,
/// without building a representation of the document.  Values are bound to shapes per Smithy's XML binding
/// rules (https://smithy.io/2.0/spec/protocol-traits.html#xml-bindings):
/// - A structure or union is an element, with each member in a child element named by the member's `xmlName`,
///   or the member name if it has none.  Members with `xmlAttribute` are read from attributes of the element.
///   Elements that don't match a member are skipped.
/// - A list is a wrapper element with one child element per item, named by the list member's `xmlName`,
///   or `member`.  A flattened list (`xmlFlattened`) has no wrapper: each item is an element named for the
///   structure member.
/// - A map is a wrapper element with one `entry` child element per entry, each containing a key element and
///   a value element, named by the `xmlName` of the map's key & value members, or `key` & `value`.  A flattened
///   map has no wrapper: each entry is an element named for the structure member.
/// - A scalar is the text of an element or the value of an attribute.  Timestamps are `date-time` unless the
///   `timestampFormat` trait says otherwise, and blobs are base64-encoded.
///
/// The elements of a flattened list or map need not be adjacent.  Each run of adjacent elements is passed to
/// the structure's `deserializeMember` separately, and the list or map read from each run includes the items
/// or entries of the runs before it, so the last value the member is set to is complete.
///
/// Namespaces are not used to match elements: names are compared as written, including any prefix.
///
/// Because the XML is read as a stream, each deserializer must be read at most once, and a deserializer for
/// a child element must be finished with before its parent is read further.  Code-generated deserialization
/// does this naturally.
///
/// The protocols wrap the shape being deserialized in protocol-specific elements, i.e.
/// `<OperationResponse><OperationResult>...` for an `awsQuery` output, or `<ErrorResponse><Error>...` for
/// an error.  Use ``child(named:)`` to reach the shape inside those wrappers.
@_spi(SchemaBasedSerde)
public final class Deserializer: ShapeDeserializer {
    typealias Attribute = XMLEventReader.Attribute

    /// The XML that this deserializer reads.
    enum Position {
        /// Nothing.  Reads as an empty structure, list, or map; reading a scalar throws.
        case empty
        /// An element, whose start has been read.  Its content is read by this deserializer.
        case element(name: String, attributes: [Attribute])
        /// A run of adjacent elements with the same name, which are the items or entries of a flattened
        /// list or map.  The start of the first element has been read.  `previousRuns` holds the collection
        /// read from earlier runs of the same member, if any.
        case flattened(name: String, attributes: [Attribute], previousRuns: FlattenedRuns)
        /// The value of an attribute.
        case attribute(String)
    }

    /// The list or map read from the runs of a flattened member so far, as `[E]` or `[String: V]`.
    final class FlattenedRuns {
        var collection: Any?
    }

    let reader: XMLEventReader
    let position: Position

    /// `true` if this deserializer reads the root element, so the rest of the XML is checked once it is read.
    private let isRoot: Bool

    /// `true` once the content of this deserializer's elements has been read through the end.
    private var isFinished = false

    /// Creates a deserializer that reads the root element of the passed XML.
    ///
    /// Empty data, or data that is only whitespace, deserializes as an empty structure.
    /// - Parameter data: The XML to be deserialized.
    /// - Throws: `SerializerError` if the start of the data cannot be parsed as XML.  Errors later in the
    ///   data are thrown when that part of the XML is read.
    public convenience init(data: Data) throws {
        let reader = try XMLEventReader(data: data)
        var position = Position.empty
        while true {
            switch try reader.next() {
            case .start(let name, let attributes):
                position = .element(name: name, attributes: attributes)
            case .text:
                continue
            case .end, .endOfDocument:
                break
            }
            break
        }
        self.init(reader: reader, position: position, isRoot: true)
    }

    init(reader: XMLEventReader, position: Position, isRoot: Bool = false) {
        self.reader = reader
        self.position = position
        self.isRoot = isRoot
    }

    /// The name of the element this deserializer reads, as written in the XML including any prefix.
    ///
    /// `nil` if this deserializer does not read an element.
    public var elementName: String? {
        guard case .element(let name, _) = position else { return nil }
        return name
    }

    /// Returns a deserializer for the first child element with the passed name.
    ///
    /// Child elements before it are skipped.  If there is no such element, the returned deserializer reads as
    /// an empty structure.  Use this to reach the shape inside a protocol's wrapper elements, i.e.
    /// `deserializer.child(named: "GetThingResult")`.
    /// - Parameter name: The name of the child element, as written in the XML including any prefix.
    /// - Returns: A deserializer for the child element.
    public func child(named name: String) throws -> Deserializer {
        guard case .element = position, !isFinished else { return Deserializer(reader: reader, position: .empty) }
        while true {
            switch try reader.next() {
            case .start(let childName, let attributes):
                if childName == name {
                    return Deserializer(reader: reader, position: .element(name: childName, attributes: attributes))
                }
                try reader.skipRemainderOfElement()
            case .text:
                continue
            case .end:
                try didFinish()
                return Deserializer(reader: reader, position: .empty)
            case .endOfDocument:
                throw SerializerError("XML ended inside element \(name)")
            }
        }
    }

    // MARK: - Aggregate types

    public func readStruct<T: DeserializableStruct>(_ schema: Schema, _ value: inout T) throws {
        let structureSchema = schema.type == .member ? (schema.target ?? schema) : schema
        let lookup = try structureSchema.getOrCreateExtension(XMLMemberLookupExtension.self)

        // Pre-fill members that have the required trait but no default with a zero/false/empty value.
        for member in lookup.requiredMembers {
            try value.deserializeMember(member, Self.defaultValueDeserializer)
        }

        let attributes: [Attribute]
        switch position {
        case .empty:
            return
        case .element(_, let elementAttributes):
            attributes = elementAttributes
        case .flattened, .attribute:
            throw SerializerError("Expected an element for structure \(structureSchema.id)")
        }

        for (name, member) in lookup.attributeMembers {
            guard let attribute = attributes.first(where: { $0.name == name }) else { continue }
            try value.deserializeMember(member, Deserializer(reader: reader, position: .attribute(attribute.value)))
        }

        // The collections read so far for flattened members, by member index.
        var flattenedRuns = [Int: FlattenedRuns]()
        try readChildren { name, attributes in
            guard let member = lookup.elementMembers[name] else { return false }
            let position: Position
            if member.isFlattened {
                let previousRuns = flattenedRuns[member.schema.index] ?? FlattenedRuns()
                flattenedRuns[member.schema.index] = previousRuns
                position = .flattened(name: name, attributes: attributes, previousRuns: previousRuns)
            } else {
                position = .element(name: name, attributes: attributes)
            }
            let child = Deserializer(reader: reader, position: position)
            try value.deserializeMember(member.schema, child)
            try child.finish()
            return true
        }
    }

    public func readList<E>(_ schema: Schema, _ consumer: ReadValueConsumer<E>) throws -> [E] {
        var items = [E]()
        switch position {
        case .empty:
            break
        case .element:
            let itemName = schema.member.getTrait(XMLNameTrait.self)?.name ?? "member"
            try readChildren { name, attributes in
                guard name == itemName else { return false }
                items.append(try readChild(name: name, attributes: attributes, consumer))
                return true
            }
        case .flattened(_, _, let previousRuns):
            items = previousRuns.collection as? [E] ?? []
            previousRuns.collection = nil // release it, so appending to items doesn't copy
            try readFlattened { name, attributes in
                items.append(try readChild(name: name, attributes: attributes, consumer))
            }
            previousRuns.collection = items
        case .attribute:
            throw SerializerError("Expected an element for list \(schema.id)")
        }
        return items
    }

    public func readMap<V>(_ schema: Schema, _ consumer: ReadValueConsumer<V>) throws -> [String: V] {
        let keyName = schema.key.getTrait(XMLNameTrait.self)?.name ?? "key"
        let valueName = schema.value.getTrait(XMLNameTrait.self)?.name ?? "value"
        var map = [String: V]()
        func readEntry(name: String, attributes: [Attribute]) throws {
            let entry = Deserializer(reader: reader, position: .element(name: name, attributes: attributes))
            if let (key, value) = try entry.readEntry(keyName: keyName, valueName: valueName, consumer) {
                map[key] = value
            }
        }
        switch position {
        case .empty:
            break
        case .element:
            try readChildren { name, attributes in
                guard name == "entry" else { return false }
                try readEntry(name: name, attributes: attributes)
                return true
            }
        case .flattened(_, _, let previousRuns):
            map = previousRuns.collection as? [String: V] ?? [:]
            previousRuns.collection = nil // release it, so adding to map doesn't copy
            try readFlattened(readEntry(name:attributes:))
            previousRuns.collection = map
        case .attribute:
            throw SerializerError("Expected an element for map \(schema.id)")
        }
        return map
    }

    // MARK: - Scalar types

    public func readBoolean(_ schema: Schema) throws -> Bool {
        switch try trimmedText(schema) {
        case "true": return true
        case "false": return false
        case let text: throw SerializerError("\(schema.id): \"\(text)\" is not a boolean")
        }
    }

    public func readBlob(_ schema: Schema) throws -> Data {
        let text = try self.text(schema)
        guard let data = Data(base64Encoded: text, options: .ignoreUnknownCharacters) else {
            throw SerializerError("\(schema.id): text is not valid base64")
        }
        return data
    }

    public func readByte(_ schema: Schema) throws -> Int8 {
        try integer(schema)
    }

    public func readShort(_ schema: Schema) throws -> Int16 {
        try integer(schema)
    }

    public func readInteger(_ schema: Schema) throws -> Int32 {
        try integer(schema)
    }

    public func readLong(_ schema: Schema) throws -> Int64 {
        try integer(schema)
    }

    public func readFloat(_ schema: Schema) throws -> Float {
        try floatingPoint(schema)
    }

    public func readDouble(_ schema: Schema) throws -> Double {
        try floatingPoint(schema)
    }

    public func readBigInteger(_ schema: Schema) throws -> Int64 {
        try integer(schema)
    }

    public func readBigDecimal(_ schema: Schema) throws -> Double {
        try floatingPoint(schema)
    }

    public func readString(_ schema: Schema) throws -> String {
        try text(schema)
    }

    public func readDocument(_ schema: Schema) throws -> any SmithyDocument {
        throw SerializerError("\(schema.id): document types are not supported in XML")
    }

    public func readTimestamp(_ schema: Schema) throws -> Date {
        let format = schema.getTrait(TimestampFormatTrait.self)?.format ?? .dateTime
        let text = try trimmedText(schema)
        switch format {
        case .epochSeconds:
            guard let seconds = Double(text) else {
                throw SerializerError("\(schema.id): \"\(text)\" is not a valid epoch-seconds timestamp")
            }
            return Date(timeIntervalSince1970: seconds)
        case .dateTime, .httpDate:
            guard let date = TimestampFormatter(format: format).date(from: text) else {
                throw SerializerError("\(schema.id): \"\(text)\" is not a valid \(format) timestamp")
            }
            return date
        }
    }

    public var mediaType: String? { "application/xml" }

    // MARK: - Reading elements

    /// Supplies zero/false/empty values for `@required` members that have no `@default`.
    private static let defaultValueDeserializer = DefaultValueDeserializer()

    /// Reads the content of this deserializer's element through its end, calling `body` with the start of each
    /// child element.  `body` reads the child through its end and returns `true`, or returns `false` and the
    /// child is skipped.  Text is ignored.
    private func readChildren(_ body: (String, [Attribute]) throws -> Bool) throws {
        guard !isFinished else { return }
        while true {
            switch try reader.next() {
            case .start(let name, let attributes):
                if try !body(name, attributes) {
                    try reader.skipRemainderOfElement()
                }
            case .text:
                continue
            case .end:
                try didFinish()
                return
            case .endOfDocument:
                throw SerializerError("XML ended inside an element")
            }
        }
    }

    /// Reads a run of adjacent elements with the same name, calling `body` with the start of each one.
    /// `body` reads the element through its end.  Reading stops before the next element with another name,
    /// or before the end of the enclosing element.
    private func readFlattened(_ body: (String, [Attribute]) throws -> Void) throws {
        guard !isFinished, case .flattened(let runName, let firstAttributes, _) = position else { return }
        try body(runName, firstAttributes)
        while true {
            switch try reader.peek() {
            case .start(let name, let attributes) where name == runName:
                _ = try reader.next()
                try body(name, attributes)
            case .text:
                // Text between elements is ignored by the enclosing element, so it may be read here.
                _ = try reader.next()
            case .start, .end, .endOfDocument:
                isFinished = true
                return
            }
        }
    }

    /// Reads a child element, whose start was just read, with `consumer`.
    private func readChild<V>(name: String, attributes: [Attribute], _ consumer: ReadValueConsumer<V>) throws -> V {
        let child = Deserializer(reader: reader, position: .element(name: name, attributes: attributes))
        let value = try consumer(child)
        try child.finish()
        return value
    }

    /// Reads a map entry from this deserializer's element.
    ///
    /// Returns `nil` for an entry without both a key & a value, since it carries nothing that can be stored.
    private func readEntry<V>(
        keyName: String,
        valueName: String,
        _ consumer: ReadValueConsumer<V>
    ) throws -> (String, V)? {
        var key: String?
        var value: V?
        // A value before the key is held as unread events until the key has been read.
        var heldValue: [XMLEventReader.Event]?
        try readChildren { name, attributes in
            if name == keyName && key == nil {
                key = try Deserializer(reader: reader, position: .element(name: name, attributes: attributes))
                    .text(nil)
            } else if name == valueName && value == nil && heldValue == nil {
                if key != nil {
                    value = try readChild(name: name, attributes: attributes, consumer)
                } else {
                    heldValue = [.start(name: name, attributes: attributes)] + (try reader.readRemainderOfElement())
                }
            } else {
                return false
            }
            return true
        }
        if let heldValue, key != nil {
            reader.unread(heldValue)
            if case .start(let name, let attributes) = try reader.next() {
                value = try readChild(name: name, attributes: attributes, consumer)
            }
        }
        guard let key, let value else { return nil }
        return (key, value)
    }

    /// Reads through the end of this deserializer's element, if it hasn't been read already.
    ///
    /// Called after a deserializer is passed to code that may not read all of it, i.e. a generated
    /// `deserializeMember` that doesn't read members it doesn't recognize.
    private func finish() throws {
        guard !isFinished else { return }
        switch position {
        case .element, .flattened:
            try reader.skipRemainderOfElement()
            try didFinish()
        case .empty, .attribute:
            isFinished = true
        }
    }

    private func didFinish() throws {
        isFinished = true
        if isRoot { try reader.readToEnd() }
    }

    /// The text of the element or attribute being read, exactly as it appears in the XML.
    ///
    /// An element with no text, i.e. `<a/>` or `<a></a>`, has empty text.  Child elements are skipped.
    private func text(_ schema: Schema?) throws -> String {
        switch position {
        case .attribute(let value):
            isFinished = true
            return value
        case .element where !isFinished:
            var bytes = [UInt8]()
            while true {
                switch try reader.next() {
                case .text(let text):
                    if bytes.isEmpty { bytes = text } else { bytes.append(contentsOf: text) }
                case .start:
                    try reader.skipRemainderOfElement()
                case .end:
                    try didFinish()
                    // libxml2 always delivers UTF-8, so decoding can't fail.
                    // swiftlint:disable:next optional_data_string_conversion
                    return String(decoding: bytes, as: UTF8.self)
                case .endOfDocument:
                    throw SerializerError("XML ended inside an element")
                }
            }
        case .element, .empty, .flattened:
            let id = schema.map { "\($0.id)" } ?? "map key"
            throw SerializerError("\(id): expected an element or attribute containing a value")
        }
    }

    /// The text being read, with leading & trailing whitespace removed, for reading non-string values.
    private func trimmedText(_ schema: Schema) throws -> String {
        try text(schema).trimmingXMLWhitespace
    }

    private func integer<T: FixedWidthInteger>(_ schema: Schema) throws -> T {
        let text = try trimmedText(schema)
        guard let value = T(text) else {
            throw SerializerError("\(schema.id): \"\(text)\" is not a valid \(T.self)")
        }
        return value
    }

    private func floatingPoint<T: BinaryFloatingPoint & LosslessStringConvertible>(_ schema: Schema) throws -> T {
        let text = try trimmedText(schema)
        switch text {
        case "NaN": return .nan
        case "Infinity": return .infinity
        case "-Infinity": return -.infinity
        default:
            // Swift also parses "inf", "nan", and hex floats, none of which are valid in Smithy XML.
            guard text.first.map({ $0.isNumber || $0 == "-" || $0 == "+" || $0 == "." }) == true,
                  !text.contains("x"), !text.contains("X"), let value = T(text), value.isFinite else {
                throw SerializerError("\(schema.id): \"\(text)\" is not a valid \(T.self)")
            }
            return value
        }
    }
}
