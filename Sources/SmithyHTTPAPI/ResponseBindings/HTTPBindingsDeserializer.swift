//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import struct Foundation.Date
@_spi(SchemaBasedSerde)
import class Smithy.HTTPHeaderTrait
@_spi(SchemaBasedSerde)
import class Smithy.HTTPResponseCodeTrait
@_spi(SchemaBasedSerde)
import class Smithy.Schema
@_spi(SchemaBasedSerde)
import protocol Smithy.SmithyDocument
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.Codec
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.DeserializableStruct
@_spi(SchemaBasedSerde)
import class SmithySerialization.DefaultValueDeserializer
@_spi(SchemaBasedSerde)
import struct SmithySerialization.Operation
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.ShapeDeserializer
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.ThrowByDefaultShapeDeserializer

@_spi(SchemaBasedSerde)
public class HTTPBindingsDeserializer: ThrowByDefaultShapeDeserializer {
    let codec: any Codec
    let bindings: [HTTPBinding]
    let response: HTTPResponse
    let data: Data?

    public init<Input, Output>(operation: Operation<Input, Output>, codec: any Codec, response: HTTPResponse, data: Data?) throws {
        self.codec = codec
        self.response = response
        self.bindings = try operation.inputSchema.getOrCreateExtension(HTTPBindingsExtension.self).bindings
        self.data = data
    }

    public func readStruct<T: DeserializableStruct>(_ schema: Schema, _ value: inout T) throws {
        // TODO: handle the httpHeader and httpParamHeader traits here

        // deserialize any HTTP response code-bound members
        for index in self.bindings.indices where self.bindings[index] == .responseCode {
            try value.deserializeMember(schema.members[index], HTTPResponseCodeDeserializer(response: response))
        }

        // If this is a non-streaming response, populate either the HTTP output payload or the
        // unbound output fields from the body.
        guard let data else { return }
        if let payloadIndex = self.bindings.firstIndex(of: .payload) {
            let payloadMemberSchema = schema.members[payloadIndex]
            let payloadDeserializer = HTTPPayloadDeserializer(codec: codec, data: data)
            try value.deserializeMember(payloadMemberSchema, payloadDeserializer)
        } else {
            let bodyDeserializer = try codec.makeDeserializer(data: data)
            try bodyDeserializer.readStruct(schema, &value)
        }
    }
}
