//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import enum Smithy.ByteStream
@_spi(SchemaBasedSerde)
import class Smithy.HTTPTrait
@_spi(SchemaBasedSerde)
import class Smithy.Schema
@_spi(SchemaBasedSerde)
import struct Smithy.ShapeID
import enum Smithy.ShapeType
import protocol Smithy.SmithyDocument
import struct Smithy.URIQueryItem
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.Codec
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.InterceptingSerializer
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.NoOpByDefaultShapeSerializer
@_spi(SchemaBasedSerde)
import class SmithySerialization.NoOpSerializer
@_spi(SchemaBasedSerde)
import struct SmithySerialization.Operation
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.SerializableStruct
@_spi(SchemaBasedSerde)
import struct SmithySerialization.SerializerError
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.ShapeSerializer

@_spi(SchemaBasedSerde)
public final class HTTPBindingsSerializer: NoOpByDefaultShapeSerializer {
    let bindings: [HTTPBinding]
    public let method: HTTPMethodType
    private let mux: RequestBindingMultiplexer
    private let contentType: String
    private let defaultBody: Data?

    /// The query items from the literal query string, if any, in the operation's `@http` URI.
    ///
    /// These are fixed by the model, so they are parsed once when this serializer is created.
    private let uriQueryItems: [URIQueryItem]

    public init<Input, Output>(codec: any Codec, operation: Operation<Input, Output>, contentType: String, defaultBody: Data?) throws {
        guard let httpTrait = operation.schema.getTrait(HTTPTrait.self) else {
            throw SerializerError("no HTTP trait for operation \(operation.schema.id)")
        }
        guard let method = HTTPMethodType(rawValue: httpTrait.method.uppercased()) else {
            throw SerializerError("unsupported HTTP method \(httpTrait.method) for operation \(operation.schema.id)")
        }
        self.method = method
        let bindingsExtension = try operation.inputSchema.getOrCreateExtension(HTTPBindingsExtension.self)
        self.bindings = bindingsExtension.bindings
        let payloadType = bindingsExtension.payloadType

        // The URI may end with a literal query string.  Split it off & parse its query items now;
        // only the path portion of the URI is subject to label substitution.
        let (path, literalQuery) = Self.split(uri: httpTrait.uri)
        self.uriQueryItems = Self.queryItems(literalQuery: literalQuery)
        self.mux = try RequestBindingMultiplexer(codec: codec, bindings: self.bindings, uri: path, payloadType: payloadType, defaultBody: defaultBody)
        self.contentType = contentType
        self.defaultBody = defaultBody
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

    public func writeStruct<S: SerializableStruct>(_ schema: Schema, _ value: S) throws {
        // This will only ever be called on the input of an operation.
        // Use the multiplexer to serialize all members of this input struct,
        // selecting the right binding serializer for the job
        try value.serializeMembers(schema, self.mux)

        // If there was no payload, serialize the body-bound members
        if !self.bindings.contains(.payload) && self.bindings.contains(.body) {
            // Wrap the structure in a proxy and serialize it
            // The proxy writes members that are bound elsewhere to a no-op serializer
            let proxy = HTTPRequestBodyProxy(bindings: self.bindings, input: value)
            try mux.bodySerializer.writeStruct(schema, proxy)
        }
    }

    public var uri: String {
        self.mux.labelSerializer.uri
    }

    public var queryItems: [URIQueryItem] {

        // The URI's literal query items and explicit `@httpQuery` bindings both take precedence over
        // `@httpQueryParams`; when a name is bound more than one way, the query-params entries for that
        // name are dropped.  All explicit query items are preserved as-is, including repeats produced
        // by list-valued query members.
        let queryItems = self.uriQueryItems + self.mux.querySerializer.queryItems
        let queryNames = Set(queryItems.map(\.name))
        let queryParamsItems = self.mux.queryParamsSerializer.queryItems.filter { !queryNames.contains($0.name) }

        // Return all sources of query items together
        return queryItems + queryParamsItems
    }

    public var headers: Headers {
        // An explicit `@httpHeader` binding takes precedence over an `@httpPrefixHeaders` entry that
        // resolves to the same header name; that entry is dropped.  A collision is only possible when
        // the prefix is empty, since a non-empty prefix may not overlap with an `@httpHeader` binding.
        var headers = self.mux.headerSerializer.headers
        let prefixHeaders = self.mux.prefixHeadersSerializer.headers.headers
        for prefixHeader in prefixHeaders where !headers.exists(name: prefixHeader.name) {
            headers.add(prefixHeader)
        }
        return headers
    }

    public var data: Data? {
        get throws {
            try self.mux.data
        }
    }

    public var body: ByteStream {
        guard let resolvedData = self.mux.resolvedData else {
            return .noStream
        }
        return .data(resolvedData)
    }

    public var mediaType: String? {
        switch body {
        case .noStream:
            nil
        default:
            self.mux.payloadSerializer?.contentType ?? self.contentType
        }
    }
}

/// When passed into an input structure member, it selects the correct serializer to use based on the HTTP binding for that member.
private struct RequestBindingMultiplexer: InterceptingSerializer {
    let bindings: [HTTPBinding]
    let headerSerializer: HTTPHeaderSerializer
    let labelSerializer: HTTPLabelSerializer
    let prefixHeadersSerializer: HTTPPrefixHeadersSerializer
    let querySerializer: HTTPQuerySerializer
    let queryParamsSerializer: HTTPQueryParamsSerializer
    let bodySerializer: any ShapeSerializer
    let payloadSerializer: HTTPPayloadSerializer?
    let noOpSerializer: NoOpSerializer

    init(codec: any Codec, bindings: [HTTPBinding], uri: String, payloadType: ShapeType?, defaultBody: Data?) throws {
        self.bindings = bindings
        self.headerSerializer = HTTPHeaderSerializer()
        self.labelSerializer = HTTPLabelSerializer(uri: uri)
        self.prefixHeadersSerializer = HTTPPrefixHeadersSerializer()
        self.querySerializer = HTTPQuerySerializer()
        self.queryParamsSerializer = HTTPQueryParamsSerializer()
        self.bodySerializer = try codec.makeSerializer()
        if let payloadType {
            let resolvedDefaultBody = [ShapeType.structure, .union, .document].contains(payloadType) ? defaultBody : nil
            self.payloadSerializer = HTTPPayloadSerializer(serializer: self.bodySerializer, defaultBody: resolvedDefaultBody)
        } else {
            self.payloadSerializer = nil
        }
        self.noOpSerializer = NoOpSerializer()
    }

    // Select the serializer that matches this input member's binding.
    // Body is serialized separately, so no-op is used here.
    func before(_ schema: Schema) throws -> any ShapeSerializer {
        return switch self.bindings[schema.index] {
        case .header:
            headerSerializer
        case .label:
            labelSerializer
        case .payload:
            payloadSerializer ?? noOpSerializer
        case .prefixHeaders:
            prefixHeadersSerializer
        case .query:
            querySerializer
        case .queryParams:
            queryParamsSerializer
        case .responseCode, .body: // responseCode should never appear in an input
            noOpSerializer
        }
    }

    // Return the payload if there is one, else the body.
    var data: Data? {
        get throws {
            resolvedData
        }
    }

    var resolvedData: Data? {
        try? self.payloadSerializer?.data ?? self.bodySerializer.data
    }
}
