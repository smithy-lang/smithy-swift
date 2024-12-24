//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import struct Foundation.Date
import protocol Smithy.SmithyDocument

@_spi(SchemaBasedSerde)
public let unitSchema = SimpleSchema<Void>(
    namespace: "smithy.api",
    name: "Unit",
    type: .structure
)

@_spi(SchemaBasedSerde)
public let booleanSchema = SimpleSchema<Bool>(
    namespace: "smithy.api",
    name: "Boolean",
    type: .boolean
)

@_spi(SchemaBasedSerde)
public let byteSchema = SimpleSchema<Int8>(
    namespace: "smithy.api",
    name: "Byte",
    type: .byte
)

@_spi(SchemaBasedSerde)
public let shortSchema = SimpleSchema<Int16>(
    namespace: "smithy.api",
    name: "Short",
    type: .short
)

@_spi(SchemaBasedSerde)
public let integerSchema = SimpleSchema<Int>(
    namespace: "smithy.api",
    name: "Integer",
    type: .integer
)

@_spi(SchemaBasedSerde)
public let longSchema = SimpleSchema<Int>(
    namespace: "smithy.api",
    name: "Long",
    type: .long
)

@_spi(SchemaBasedSerde)
public let floatSchema = SimpleSchema<Float>(
    namespace: "smithy.api",
    name: "Float",
    type: .float
)

@_spi(SchemaBasedSerde)
public let doubleSchema = SimpleSchema<Double>(
    namespace: "smithy.api",
    name: "Double",
    type: .double
)

@_spi(SchemaBasedSerde)
public let stringSchema = SimpleSchema<String>(
    namespace: "smithy.api",
    name: "String",
    type: .string
)

@_spi(SchemaBasedSerde)
public let documentSchema = SimpleSchema<SmithyDocument>(
    namespace: "smithy.api",
    name: "Document",
    type: .document
)

@_spi(SchemaBasedSerde)
public let blobSchema = SimpleSchema<Data>(
    namespace: "smithy.api",
    name: "Blob",
    type: .blob
)

@_spi(SchemaBasedSerde)
public let timestampSchema = SimpleSchema<Date>(
    namespace: "smithy.api",
    name: "Timestamp",
    type: .timestamp
)
