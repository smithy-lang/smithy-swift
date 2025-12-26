//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import protocol SmithySerialization.Codec
import protocol SmithySerialization.ShapeSerializer
import protocol SmithySerialization.ShapeDeserializer

public struct Codec: SmithySerialization.Codec {

    public init() {}

    public func makeSerializer() throws -> any ShapeSerializer {
        try Serializer()
    }

    public func makeDeserializer() throws -> any ShapeDeserializer {
        try Deserializer()
    }
}
