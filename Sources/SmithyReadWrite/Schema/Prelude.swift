//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

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
public let integerSchema = SimpleSchema<Int>(
    namespace: "smithy.api",
    name: "Integer",
    type: .integer
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
