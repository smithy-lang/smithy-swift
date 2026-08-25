//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
@_spi(SchemaBasedSerde)
import class Smithy.Schema
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.Codec
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.DeserializableStruct
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.ThrowByDefaultShapeDeserializer

/// Deserializes an HTTP response into the output or error structure of an operation.
///
/// Each member of the structure is deserialized by the deserializer for that member's HTTP binding;
/// a member with no binding is deserialized from the response body.
@_spi(SchemaBasedSerde)
public class HTTPBindingsDeserializer: ThrowByDefaultShapeDeserializer {
    let codec: any Codec
    let response: HTTPResponse
    let data: Data?

    public init(codec: any Codec, response: HTTPResponse, data: Data?) {
        self.codec = codec
        self.response = response
        self.data = data
    }

    public func readStruct<T: DeserializableStruct>(_ schema: Schema, _ value: inout T) throws {
        // The bindings are resolved from the structure being deserialized, which may be the
        // operation's output or any one of its errors.  Only the top-level members of that
        // structure carry HTTP bindings.
        let bindings = try schema.getOrCreateExtension(HTTPBindingsExtension.self).bindings

        // If this is a non-streaming response, populate either the HTTP output payload or the
        // unbound output fields from the body.  The body is deserialized before the bindings below
        // because it fills in a placeholder value for every required member that the body omits;
        // a value carried elsewhere in the response takes precedence over that placeholder.
        if let payloadIndex = bindings.firstIndex(of: .payload), let data {
            let payloadMemberSchema = schema.members[payloadIndex]
            let payloadDeserializer = HTTPPayloadDeserializer(codec: codec, data: data)
            try value.deserializeMember(payloadMemberSchema, payloadDeserializer)
        } else if let data {
            let bodyDeserializer = try codec.makeDeserializer(data: data)
            try bodyDeserializer.readStruct(schema, &value)
        }

        // Deserialize the members bound to HTTP headers, then the map member bound to prefixed
        // headers if there is one.  Each of these deserializers fills only the members that carry
        // its own trait, and leaves every other member of the structure untouched.
        try HTTPHeaderDeserializer(headers: response.headers).readStruct(schema, &value)
        try HTTPPrefixHeadersDeserializer(headers: response.headers).readStruct(schema, &value)

        // deserialize any HTTP response code-bound members
        for index in bindings.indices where bindings[index] == .responseCode {
            try value.deserializeMember(schema.members[index], HTTPResponseCodeDeserializer(response: response))
        }
    }
}
