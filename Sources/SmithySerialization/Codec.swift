//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data

@_spi(SchemaBasedSerde)
public protocol Codec: Sendable {
    func makeSerializer() throws -> any ShapeSerializer
    func makeDeserializer(data: Data) throws -> any ShapeDeserializer
    var emptyRequest: Data? { get }
    var emptyResponse: Data? { get }
    var serializerMediaType: String? { get }
    var deserializerMediaType: String? { get }

    /// `true` if a structure bound to the HTTP payload is written with the payload member's schema, rather
    /// than the schema of the member's target.
    ///
    /// A codec whose format names the payload for the member, i.e. XML, which names the root element for
    /// the payload member's `xmlName` if it has one, needs the member's schema.
    var writesPayloadWithMemberSchema: Bool { get }
}

public extension Codec {

    var emptyRequest: Data? { nil }
    var emptyResponse: Data? { nil }
    var serializerMediaType: String? { nil }
    var deserializerMediaType: String? { nil }
    var writesPayloadWithMemberSchema: Bool { false }
}
