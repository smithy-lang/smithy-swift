//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(SchemaBasedSerde)
import class Smithy.HTTPLabelTrait
@_spi(SchemaBasedSerde)
import class Smithy.HTTPTrait
@_spi(SchemaBasedSerde)
import class Smithy.Schema
@_spi(SchemaBasedSerde)
import protocol Smithy.SchemaExtension
@_spi(SchemaBasedSerde)
import var Smithy.schemaExtensionUniqueIndexCounter
@_spi(SchemaBasedSerde)
import class Smithy.StreamingTrait
import struct Smithy.URIQueryItem
import struct SmithySerialization.SerializerError

/// Everything the HTTP request bindings derive from an operation, resolved once for that operation.
///
/// All of this is fixed by the model, so a request reads it instead of recomputing it.  It is held in
/// a single extension so that serializing a request costs one schema extension lookup rather than one
/// per binding kind plus one per bound member; those lookups take a lock and a dynamic cast, and they
/// were a measurable share of the time spent serializing a small request.
@_spi(SchemaBasedSerde)
public final class HTTPOperationExtension: SchemaExtension {
    public static let uniqueIndex: Int = schemaExtensionUniqueIndexCounter.getNextIndex()

    /// The HTTP method for this operation.
    public let method: HTTPMethodType

    /// How this operation's input members are bound to the parts of the request.
    public let input: HTTPBindingsExtension

    /// The operation's URI path, split on `/`.
    ///
    /// A segment bound to a member holds the template text, i.e. `{Bucket}`, until a request replaces
    /// it with that member's value.
    public let segments: [Substring]

    /// The query items written literally into the operation's URI.
    public let uriQueryItems: [URIQueryItem]

    /// The index of the URI segment each input member is bound to, or `nil` for a member that is not
    /// bound to a segment.  Indexed by the member's `index`.
    public let labelSegmentIndex: [Int?]

    /// Whether each input member's `httpLabel` binding is greedy.  Indexed by the member's `index`.
    public let labelIsGreedy: [Bool]

    /// How this operation's request body is streamed, or `nil` if it is not streamed.
    public let requestStreamingType: HTTPStreamingType?

    /// The output member that the response body streams into, or `nil` if there is none.
    public let responseStreamingMember: Schema?

    /// Creates the bindings for an operation.
    /// - Parameter schema: The schema of the operation.  Must be of type `.operation` and carry the
    ///   `http` trait.
    public required init(schema: Schema) throws {
        guard let httpTrait = schema.getTrait(HTTPTrait.self) else {
            throw SerializerError("no HTTP trait for operation \(schema.id)")
        }
        guard let method = HTTPMethodType(rawValue: httpTrait.method.uppercased()) else {
            throw SerializerError("unsupported HTTP method \(httpTrait.method) for operation \(schema.id)")
        }
        self.method = method

        let inputSchema = try schema.input
        self.input = try inputSchema.getOrCreateExtension(HTTPBindingsExtension.self)

        let (path, literalQuery) = Self.split(uri: httpTrait.uri)
        let segments = path.split(separator: "/", omittingEmptySubsequences: false)
        self.segments = segments
        self.uriQueryItems = Self.queryItems(literalQuery: literalQuery)

        // Resolve every label-bound member to its segment up front, so that serializing a label is a
        // lookup by member index instead of a search through the segments.
        //
        // Only members carrying the `httpLabel` trait are bound, so no other member can be written into
        // the path.  The model is validated before code is generated from it, but this runs only once
        // per operation, so a URI and input that disagree are reported here instead of sending a
        // request with label template text left in its path.
        let members = inputSchema.members
        var labelSegmentIndex = [Int?](repeating: nil, count: members.count)
        var labelIsGreedy = [Bool](repeating: false, count: members.count)
        for (segmentIndex, segment) in segments.enumerated() {
            guard let label = try Self.label(in: segment, uri: httpTrait.uri) else { continue }
            let member = members.first { member in
                member.hasTrait(HTTPLabelTrait.self) && member.id.member.map { $0[...] == label.name } ?? false
            }
            guard let member else {
                throw SerializerError(
                    "URI label {\(label.name)} in \(httpTrait.uri) for operation \(schema.id) " +
                    "has no matching @httpLabel member in \(inputSchema.id)"
                )
            }
            labelSegmentIndex[member.index] = segmentIndex
            labelIsGreedy[member.index] = label.isGreedy
        }
        let unboundLabelMembers = members.filter { member in
            member.hasTrait(HTTPLabelTrait.self) && labelSegmentIndex[member.index] == nil
        }
        if let member = unboundLabelMembers.first {
            throw SerializerError(
                "@httpLabel member \(member.id) has no matching label in URI \(httpTrait.uri) " +
                "for operation \(schema.id)"
            )
        }
        self.labelSegmentIndex = labelSegmentIndex
        self.labelIsGreedy = labelIsGreedy

        self.requestStreamingType = Self.streamingType(ofMembersOf: inputSchema)
        self.responseStreamingMember = try schema.output.members.first { $0.hasTrait(StreamingTrait.self) }
    }

    // MARK: - Private methods

    /// The way the streaming member of the passed structure is streamed, if it has one.
    ///
    /// The `streaming` trait may only be applied to a union or a blob; a union is an event stream and
    /// a blob is a stream of data.
    private static func streamingType(ofMembersOf schema: Schema) -> HTTPStreamingType? {
        switch schema.members.first(where: { $0.hasTrait(StreamingTrait.self) })?.type {
        case .union: return .event
        case .blob: return .data
        default: return nil
        }
    }

    /// The label that a URI path segment is bound to, if it is a label segment.
    ///
    /// A label spans its whole segment, reading `{name}`, or `{name+}` when it is greedy.  A segment
    /// holding a brace in any other form is malformed, and throws rather than being taken as literal
    /// text or misread as a differently named label.
    private static func label(in segment: Substring, uri: String) throws -> (name: Substring, isGreedy: Bool)? {
        guard segment.contains("{") || segment.contains("}") else { return nil }
        guard segment.first == "{", segment.last == "}" else {
            throw SerializerError("URI path segment \(segment) in \(uri) is not a well-formed label")
        }
        var name = segment.dropFirst().dropLast()
        let isGreedy = name.last == "+"
        if isGreedy { name = name.dropLast() }
        guard !name.isEmpty, !name.contains("{"), !name.contains("}"), !name.contains("+") else {
            throw SerializerError("URI path segment \(segment) in \(uri) is not a well-formed label")
        }
        return (name, isGreedy)
    }

    /// Splits a URI into its path and its literal query string, if it has one.
    private static func split(uri: String) -> (path: String, literalQuery: Substring?) {
        guard let separator = uri.firstIndex(of: "?") else { return (uri, nil) }
        return (String(uri[uri.startIndex..<separator]), uri[uri.index(after: separator)...])
    }

    /// Parses the literal query string from a URI into query items.
    ///
    /// Names & values are used exactly as they appear in the model.  A name with no value, i.e. `?uploads`,
    /// becomes a query item with a `nil` value, which is rendered without a `=`.
    private static func queryItems(literalQuery: Substring?) -> [URIQueryItem] {
        guard let literalQuery else { return [] }
        return literalQuery.split(separator: "&").map { pair in
            guard let separator = pair.firstIndex(of: "=") else {
                return URIQueryItem(name: String(pair), value: nil)
            }
            let value = pair[pair.index(after: separator)...]
            return URIQueryItem(
                name: String(pair[pair.startIndex..<separator]),
                value: value.isEmpty ? nil : String(value)
            )
        }
    }
}

/// The way an HTTP message's body is streamed.
@_spi(SchemaBasedSerde)
public enum HTTPStreamingType: Sendable {

    /// The body is a stream of event stream messages, serialized from a union member.
    case event

    /// The body is a stream of data, serialized from a blob member.
    case data
}
