//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(SchemaBasedSerde)
import class Smithy.Schema

@_spi(SchemaBasedSerde)
public typealias ReadStructConsumer<T> = (Schema, inout T, any ShapeDeserializer) throws -> Void

@_spi(SchemaBasedSerde)
public protocol DeserializableStruct: DeserializableShape {
    static var readConsumer: ReadStructConsumer<Self> { get }
}
