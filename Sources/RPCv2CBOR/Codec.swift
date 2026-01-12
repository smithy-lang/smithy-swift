//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import protocol SmithySerialization.Codec
import protocol SmithySerialization.ShapeDeserializer
import protocol SmithySerialization.ShapeSerializer
import class SmithyCBOR.Serializer
import struct SmithyCBOR.Deserializer

public struct Codec: SmithySerialization.Codec {

    public init() {}

    public func makeSerializer() throws -> any ShapeSerializer {
        try Serializer()
    }

    public func makeDeserializer(data: Data) throws -> any ShapeDeserializer {
        try Deserializer(data: data)
    }
}
