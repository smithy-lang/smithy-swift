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
import class SmithySerialization.NoOpSerializer
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.ShapeSerializer
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.InterceptingSerializer

@_spi(SchemaBasedSerde)
public final class HTTPBodySerializer: InterceptingSerializer {
    private let serializer: any ShapeSerializer
    private let bindings: [HTTPBinding]
    private let noOpSerializer = NoOpSerializer()

    public init(serializer: any ShapeSerializer, bindings: [HTTPBinding]) {
        self.serializer = serializer
        self.bindings = bindings
    }

    public func before(_ schema: Schema) throws -> any ShapeSerializer {
        self.bindings[schema.index] == .body ? self.serializer : self.noOpSerializer
    }

    public var data: Data {
        get throws {
            try self.serializer.data
        }
    }
}
