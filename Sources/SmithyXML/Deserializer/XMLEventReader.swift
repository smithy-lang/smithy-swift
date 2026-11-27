//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
@preconcurrency import libxml2
import struct SmithySerialization.SerializerError

/// Reads XML as a stream of events, parsed on demand by the libxml2 SAX push parser.
///
/// The XML is fed to the parser one chunk at a time, only when the next event is requested and none are
/// pending, so no representation of the document is built: memory use is bounded by the events from one
/// chunk, plus the text of the element being read.  Element and attribute names are as written, including
/// any namespace prefix, i.e. `xsi:type`; namespaces are not resolved.  Comments and processing instructions
/// are not reported.
final class XMLEventReader {

    struct Attribute {
        /// The attribute's name as written, including the namespace prefix if one is present.
        let name: String
        let value: String
    }

    enum Event {
        /// The start of an element, with its name as written and its attributes.
        case start(name: String, attributes: [Attribute])
        /// Text content, including CDATA sections.  The text of one element may arrive in several events.
        case text([UInt8])
        /// The end of the most recently started element that has not ended.
        case end
        /// There are no more events.
        case endOfDocument
    }

    /// The maximum nesting depth of elements accepted.  Deeper documents are rejected to protect the stack
    /// during deserialization, which recurses once for each level of nesting.
    static let maxDepth = 256

    /// The number of bytes fed to the parser at a time.
    static let chunkSize = 16 * 1024

    private let data: Data
    private var offset: Data.Index
    private var parserContext: xmlParserCtxtPtr?

    /// Events parsed but not yet read.  Events before `head` have been read.
    private var events: [Event] = []
    private var head = 0

    /// The number of elements started but not ended, as parsed.
    private var parsedDepth = 0

    /// The error that stopped parsing, if any.  Once set, every read throws it.
    private var failure: SerializerError?

    /// The first error reported by libxml2, if any.
    private var parserError: String?

    /// Creates a reader for XML data.  Nothing is parsed until the first event is read.
    ///
    /// Data that is empty or only whitespace yields no events.
    init(data: Data) throws {
        self.data = data
        self.offset = data.startIndex
        guard data.contains(where: { !isXMLWhitespace($0) }) else {
            self.offset = data.endIndex
            return
        }
        guard data.count <= Int(Int32.max) else { throw SerializerError("XML document is too large to parse") }
        _ = Self.libxml2Initialized

        var handler = Self.saxHandler
        let userData = Unmanaged.passUnretained(self).toOpaque()
        guard let parserContext = xmlCreatePushParserCtxt(&handler, userData, nil, 0, nil) else {
            throw SerializerError("XML parser could not be created")
        }
        self.parserContext = parserContext

        // XML_PARSE_NOENT substitutes the predefined entities (&amp; etc.) in attribute values, which
        // libxml2 otherwise passes through re-encoded as character references.  No other entities can be
        // substituted, because documents with a DTD are rejected and the handler has no getEntity callback.
        // XML_PARSE_NONET prohibits any network access by the parser.
        let options = XML_PARSE_NOENT.rawValue | XML_PARSE_NONET.rawValue
        _ = xmlCtxtUseOptions(parserContext, Int32(options))
    }

    deinit {
        if let parserContext { xmlFreeParserCtxt(parserContext) }
    }

    /// Reads the next event.
    func next() throws -> Event {
        try fill()
        guard head < events.count else { return .endOfDocument }
        let event = events[head]
        head += 1
        if head == events.count {
            events.removeAll(keepingCapacity: true)
            head = 0
        }
        return event
    }

    /// Returns the next event without reading it.
    func peek() throws -> Event {
        try fill()
        return head < events.count ? events[head] : .endOfDocument
    }

    /// Returns events to the reader, to be read again before any others.
    func unread(_ unreadEvents: [Event]) {
        events.insert(contentsOf: unreadEvents, at: head)
    }

    /// Reads the events through the end of the element whose start was just read, and returns them.
    func readRemainderOfElement() throws -> [Event] {
        var recorded = [Event]()
        var depth = 1
        while depth > 0 {
            let event = try next()
            switch event {
            case .start: depth += 1
            case .end: depth -= 1
            case .text: break
            case .endOfDocument: throw SerializerError("XML ended inside an element")
            }
            recorded.append(event)
        }
        return recorded
    }

    /// Reads and discards events through the end of the element whose start was just read.
    func skipRemainderOfElement() throws {
        var depth = 1
        while depth > 0 {
            switch try next() {
            case .start: depth += 1
            case .end: depth -= 1
            case .text: break
            case .endOfDocument: throw SerializerError("XML ended inside an element")
            }
        }
    }

    /// Parses the rest of the XML, discarding any events, so that it is checked for well-formedness.
    func readToEnd() throws {
        events.removeAll()
        head = 0
        while offset < data.endIndex {
            try feed()
            events.removeAll(keepingCapacity: true)
        }
        if let failure { throw failure }
    }

    // MARK: - Parsing

    /// Feeds the parser until at least one event is pending, or all data has been parsed.
    private func fill() throws {
        if let failure { throw failure }
        while head == events.count && offset < data.endIndex {
            try feed()
        }
    }

    /// Feeds the next chunk of data to the parser.
    private func feed() throws {
        guard let parserContext else { return }
        let end = data.index(offset, offsetBy: Self.chunkSize, limitedBy: data.endIndex) ?? data.endIndex
        let isLast = end == data.endIndex
        let result = data[offset..<end].withUnsafeBytes { buffer in
            buffer.withMemoryRebound(to: CChar.self) { chars in
                xmlParseChunk(parserContext, chars.baseAddress, Int32(chars.count), isLast ? 1 : 0)
            }
        }
        offset = end
        if failure == nil && (result != 0 || parserContext.pointee.wellFormed == 0) {
            failure = SerializerError("XML could not be parsed: \(parserError ?? "not well-formed")")
        }
        if let failure {
            offset = data.endIndex
            throw failure
        }
    }

    private func fail(_ message: String) {
        guard failure == nil else { return }
        failure = SerializerError(message)
        if let parserContext { xmlStopParser(parserContext) }
    }

    // MARK: - SAX callbacks

    private func didStartElement(name: String, attributes: [Attribute]) {
        guard failure == nil else { return }
        guard parsedDepth < Self.maxDepth else {
            fail("XML elements are nested deeper than the maximum of \(Self.maxDepth)")
            return
        }
        parsedDepth += 1
        events.append(.start(name: name, attributes: attributes))
    }

    private func didEndElement() {
        guard failure == nil else { return }
        parsedDepth -= 1
        events.append(.end)
    }

    private func didReceiveCharacters(_ chars: UnsafePointer<UInt8>?, _ length: Int32) {
        guard failure == nil, parsedDepth > 0, let chars, length > 0 else { return }
        let buffer = UnsafeBufferPointer(start: chars, count: Int(length))
        if head < events.count, case .text(var text) = events[events.count - 1] {
            // Combine with the pending text event.  Clear the pending event first so the append doesn't copy.
            events[events.count - 1] = .end
            text.append(contentsOf: buffer)
            events[events.count - 1] = .text(text)
        } else {
            events.append(.text(Array(buffer)))
        }
    }

    private static func reader(_ context: UnsafeMutableRawPointer?) -> XMLEventReader? {
        guard let context else { return nil }
        return Unmanaged<XMLEventReader>.fromOpaque(context).takeUnretainedValue()
    }

    private static func string(_ chars: UnsafePointer<UInt8>?) -> String {
        guard let chars else { return "" }
        return String(cString: chars)
    }

    private static func qualifiedName(prefix: UnsafePointer<UInt8>?, localName: UnsafePointer<UInt8>?) -> String {
        let localName = string(localName)
        guard let prefix else { return localName }
        return "\(string(prefix)):\(localName)"
    }

    /// libxml2 must be initialized once before it is used from multiple threads.
    private static let libxml2Initialized: Void = xmlInitParser()

    private static let saxHandler: xmlSAXHandler = {
        var handler = xmlSAXHandler()
        handler.initialized = UInt32(XML_SAX2_MAGIC)

        handler.startElementNs = { context, localName, prefix, _, _, _, attributeCount, _, attributeData in
            guard let reader = XMLEventReader.reader(context) else { return }
            var attributes: [Attribute] = []
            if let attributeData, attributeCount > 0 {
                attributes.reserveCapacity(Int(attributeCount))
                // Each attribute is 5 pointers: local name, prefix, URI, value start, value end.
                for offset in stride(from: 0, to: Int(attributeCount) * 5, by: 5) {
                    let name = XMLEventReader.qualifiedName(
                        prefix: attributeData[offset + 1], localName: attributeData[offset]
                    )
                    var value = ""
                    if let start = attributeData[offset + 3], let end = attributeData[offset + 4] {
                        // libxml2 always delivers UTF-8, so decoding can't fail.
                        // swiftlint:disable:next optional_data_string_conversion
                        value = String(decoding: UnsafeBufferPointer(start: start, count: end - start), as: UTF8.self)
                    }
                    attributes.append(Attribute(name: name, value: value))
                }
            }
            reader.didStartElement(
                name: XMLEventReader.qualifiedName(prefix: prefix, localName: localName), attributes: attributes
            )
        }

        handler.endElementNs = { context, _, _, _ in
            XMLEventReader.reader(context)?.didEndElement()
        }

        handler.characters = { context, chars, length in
            XMLEventReader.reader(context)?.didReceiveCharacters(chars, length)
        }

        handler.cdataBlock = { context, chars, length in
            XMLEventReader.reader(context)?.didReceiveCharacters(chars, length)
        }

        // Documents with a DTD are rejected, so no entities other than the predefined ones are ever expanded.
        handler.internalSubset = { context, _, _, _ in
            XMLEventReader.reader(context)?.fail("XML with a document type declaration is not supported")
        }

        // Record parser errors rather than letting libxml2 print them.
        handler.serror = { context, error in
            guard let reader = XMLEventReader.reader(context), reader.parserError == nil else { return }
            let message = error?.pointee.message.map { String(cString: $0) } ?? "unknown error"
            reader.parserError = message.trimmingXMLWhitespace
        }

        return handler
    }()
}

func isXMLWhitespace(_ byte: UInt8) -> Bool {
    byte == 0x20 || byte == 0x09 || byte == 0x0A || byte == 0x0D
}

extension String {

    /// This string with leading & trailing XML whitespace (space, tab, CR, LF) removed.
    var trimmingXMLWhitespace: String {
        let bytes = Array(utf8)
        guard let first = bytes.firstIndex(where: { !isXMLWhitespace($0) }),
              let last = bytes.lastIndex(where: { !isXMLWhitespace($0) }) else { return "" }
        // libxml2 always delivers UTF-8, so decoding can't fail.
        // swiftlint:disable:next optional_data_string_conversion
        return String(decoding: bytes[first...last], as: UTF8.self)
    }
}
