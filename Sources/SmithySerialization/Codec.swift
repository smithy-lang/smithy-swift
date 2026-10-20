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
}

public extension Codec {

    var emptyRequest: Data? { nil }
    var emptyResponse: Data? { nil }
    var serializerMediaType: String? { nil }
    var deserializerMediaType: String? { nil }
}
