//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
@_spi(SchemaBasedSerde)
import class Smithy.XMLNamespaceTrait
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.Codec
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.ShapeDeserializer
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.ShapeSerializer
@_spi(SchemaBasedSerde)
import class SmithyXML.Deserializer
@_spi(SchemaBasedSerde)
import class SmithyXML.Serializer

/// restXml request & response bodies are XML.
struct Codec: SmithySerialization.Codec {

    /// The namespace for the root element of a request body that has no `xmlNamespace` of its own,
    /// i.e. the service's.
    let defaultNamespace: XMLNamespaceTrait?

    func makeSerializer() throws -> any ShapeSerializer {
        SmithyXML.Serializer(defaultNamespace: defaultNamespace)
    }

    func makeDeserializer(data: Data) throws -> any ShapeDeserializer {
        try SmithyXML.Deserializer(data: data)
    }

    var serializerMediaType: String? { "application/xml" }

    var deserializerMediaType: String? { "application/xml" }

    // The root element of a payload is named by the payload member's xmlName, if it has one.
    var writesPayloadWithMemberSchema: Bool { true }
}

/// The codec for restXml error responses, whose deserializers read the `Error` element.
///
/// The `Error` element is wrapped in an `ErrorResponse` element unless the service uses `noErrorWrapping`.
///
/// See https://smithy.io/2.0/aws/protocols/aws-restxml-protocol.html#error-response-serialization
struct ErrorCodec: SmithySerialization.Codec {

    let noErrorWrapping: Bool

    func makeSerializer() throws -> any ShapeSerializer {
        SmithyXML.Serializer()
    }

    func makeDeserializer(data: Data) throws -> any ShapeDeserializer {
        let deserializer = try SmithyXML.Deserializer(data: data)
        return noErrorWrapping ? deserializer : try deserializer.child(named: "Error")
    }

    var deserializerMediaType: String? { "application/xml" }
}
