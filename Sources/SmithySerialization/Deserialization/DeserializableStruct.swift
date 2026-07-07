//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(SchemaBasedSerde)
import class Smithy.Schema

@_spi(SchemaBasedSerde)
public protocol DeserializableStruct: DeserializableShape {

    mutating func deserializeMember(
        _ memberSchema: Schema,
        _ deserializer: any ShapeDeserializer
    ) throws
}
