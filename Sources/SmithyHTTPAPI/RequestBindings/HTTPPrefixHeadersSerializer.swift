//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(SchemaBasedSerde)
import class Smithy.HTTPPrefixHeadersTrait
@_spi(SchemaBasedSerde)
import class Smithy.Schema
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.NoOpByDefaultShapeSerializer
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.ShapeSerializer

/// Serializes the single map member bound with the `httpPrefixHeaders` trait into HTTP headers.
///
/// Each entry of the map becomes one header, named by prepending the trait's prefix to the entry's key.
///
/// The `httpPrefixHeaders` trait may only be applied to a non-sparse map of string to string, so this
/// serializer is a no-op for every other type.
@_spi(SchemaBasedSerde)
public final class HTTPPrefixHeadersSerializer: NoOpByDefaultShapeSerializer {

    /// The headers serialized so far.
    ///
    /// One header comes from each entry of a single map, so their names are distinct and a header is
    /// appended without first searching for an existing header of the same name.
    private var serialized = [Header]()

    /// The header name to use while a single map entry is being serialized,
    /// or `nil` if a map entry is not currently being serialized.
    private var name: String?

    public var headers: Headers {
        var headers = Headers()
        headers.headers = serialized
        return headers
    }

    public init() {}

    public func writeMap<V>(
        _ schema: Schema,
        _ value: [String: V],
        _ consumer: (V, any ShapeSerializer) throws -> Void
    ) throws {
        guard let prefix = schema.getTrait(HTTPPrefixHeadersTrait.self)?.prefix else { return }
        defer { self.name = nil }
        for (key, entry) in value {
            // The map key does not name a header by itself; the trait's prefix is prepended to it.
            // The name is held here for the scalar writer to use while the value is being serialized.
            self.name = prefix + key
            try consumer(entry, self)
        }
    }

    public func writeString(_ schema: Schema, _ value: String) throws {
        // Outside of a map entry there is no header name to bind to, so this is a no-op.
        guard let name else { return }
        // A map value is a scalar string, never a list element, so it is added without quoting.
        serialized.append(Header(name: name, value: value))
    }

    public var mediaType: String? { nil }
}
