//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import struct Foundation.URL
import struct Foundation.URLComponents
import enum Smithy.ByteStream
@_spi(SchemaBasedSerde)
import class Smithy.HTTPTrait
@_spi(SchemaBasedSerde)
import class Smithy.Schema
@_spi(SchemaBasedSerde)
import struct Smithy.ShapeID
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
    private let mux: BindingMultiplexer

    public init<Input, Output>(codec: any Codec, operation: Operation<Input, Output>) throws {
        guard let httpTrait = operation.schema.getTrait(HTTPTrait.self) else {
            throw SerializerError("no HTTP trait for operation \(operation.schema.id)")
        }
        guard let method = HTTPMethodType(rawValue: httpTrait.method.uppercased()) else {
            throw SerializerError("unsupported HTTP method \(httpTrait.method) for operation \(operation.schema.id)")
        }
        self.method = method
        self.bindings = try operation.inputSchema.getOrCreateExtension(HTTPBindingsExtension.self).bindings
        self.mux = try BindingMultiplexer(codec: codec, bindings: self.bindings, uri: httpTrait.uri)
    }

    public func writeStruct<S: SerializableStruct>(_ schema: Schema, _ value: S) throws {
        // This will only ever be called on the input of an operation.
        // Use the multiplexer to serialize all members of this input struct,
        // selecting the right binding serializer for the job
        try value.serializeMembers(schema, self.mux)

        // If there was no payload, serialize the body-bound members
        if !self.bindings.contains(.payload) {
            // Wrap the structure in a proxy and serialize it
            // The proxy writes members that are bound elsewhere to a no-op serializer
            let proxy = HTTPRequestBodyProxy(bindings: self.bindings, input: value)
            try mux.bodySerializer.writeStruct(schema, proxy)
        }
    }

    public var uri: String {
        String(self.mux.labelSerializer.uri.prefix { $0 != "?" })
    }

    public var queryItems: [URIQueryItem] {

        // Get the query items out of the URI, if any
        var uriQueryItems: [URIQueryItem] = []
        if let uriQueryURL = URL(string: self.mux.labelSerializer.uri) {
            let urlQueryItems = URLComponents(url: uriQueryURL, resolvingAgainstBaseURL: false)?.queryItems ?? []
            uriQueryItems = urlQueryItems.map {
                URIQueryItem(
                    name: URLEncodingUtils.urlPercentEncodedForQuery($0.name),
                    value: $0.value.map { URLEncodingUtils.urlPercentEncodedForQuery($0) }
                )
            }
        }

        // Explicit `@httpQuery` bindings take precedence over `@httpQueryParams`; when a name is
        // bound both ways, the query-params entries for that name are dropped.  All explicit query
        // items are preserved as-is, including repeats produced by list-valued query members.
        let queryItems = self.mux.querySerializer.queryItems
        let queryNames = Set(queryItems.map(\.name))
        let queryParamsItems = self.mux.queryParamsSerializer.queryItems.filter { !queryNames.contains($0.name) }

        // Return all sources of query items together
        return uriQueryItems + queryItems + queryParamsItems
    }

    public var headers: Headers {
        self.mux.headerSerializer.headers
    }

    public var data: Data {
        get throws {
            try self.mux.data
        }
    }
}

/// When passed into an input structure member, it selects the correct serializer to use based on the HTTP binding for that member.
private struct BindingMultiplexer: InterceptingSerializer {
    let bindings: [HTTPBinding]
    let headerSerializer: HTTPHeaderSerializer
    let labelSerializer: HTTPLabelSerializer
    let querySerializer: HTTPQuerySerializer
    let queryParamsSerializer: HTTPQueryParamsSerializer
    let bodySerializer: any ShapeSerializer
    let payloadSerializer: any ShapeSerializer
    let noOpSerializer: NoOpSerializer

    init(codec: any Codec, bindings: [HTTPBinding], uri: String) throws {
        self.bindings = bindings
        self.headerSerializer = HTTPHeaderSerializer()
        self.labelSerializer = HTTPLabelSerializer(uri: uri)
        self.querySerializer = HTTPQuerySerializer()
        self.queryParamsSerializer = HTTPQueryParamsSerializer()
        self.bodySerializer = try codec.makeSerializer()
        self.payloadSerializer = HTTPPayloadSerializer(serializer: self.bodySerializer)
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
            payloadSerializer
        case .query:
            querySerializer
        case .queryParams:
            queryParamsSerializer
        case .body:
            noOpSerializer
        }
    }

    // Return the payload if there is one, else the body.
    var data: Data {
        get throws {
            if self.bindings.contains(.payload) {
                try self.payloadSerializer.data
            } else {
                try self.bodySerializer.data
            }
        }
    }
}
