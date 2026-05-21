//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(SchemaBasedSerde)
public protocol DeserializableShape: Sendable {
    static func deserialize(_ deserializer: ShapeDeserializer) throws -> Self
}
