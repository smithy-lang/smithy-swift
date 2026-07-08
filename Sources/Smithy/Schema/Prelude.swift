//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// Below are schemas for all model shapes defined in the Smithy 2.0 prelude.
// Schemas for custom Smithy types may use these schemas in their definitions.

@_spi(SchemaBasedSerde)
public enum Prelude {

    public static let unitSchema: Schema =
        Schema(id: .init("smithy.api", "Unit"), type: .structure, traits: [UnitTypeTrait()])

    public static let booleanSchema: Schema =
        Schema(id: .init("smithy.api", "Boolean"), type: .boolean)

    public static let stringSchema: Schema =
        Schema(id: .init("smithy.api", "String"), type: .string)

    public static let integerSchema: Schema =
        Schema(id: .init("smithy.api", "Integer"), type: .integer)

    public static let blobSchema: Schema =
        Schema(id: .init("smithy.api", "Blob"), type: .blob)

    public static let timestampSchema: Schema =
        Schema(id: .init("smithy.api", "Timestamp"), type: .timestamp)

    public static let byteSchema: Schema =
        Schema(id: .init("smithy.api", "Byte"), type: .byte)

    public static let shortSchema: Schema =
        Schema(id: .init("smithy.api", "Short"), type: .short)

    public static let longSchema: Schema =
        Schema(id: .init("smithy.api", "Long"), type: .long)

    public static let floatSchema: Schema =
        Schema(id: .init("smithy.api", "Float"), type: .float)

    public static let doubleSchema: Schema =
        Schema(id: .init("smithy.api", "Double"), type: .double)

    public static let bigIntegerSchema: Schema =
        Schema(id: .init("smithy.api", "BigInteger"), type: .bigInteger)

    public static let bigDecimalSchema: Schema =
        Schema(id: .init("smithy.api", "BigDecimal"), type: .bigDecimal)

    public static let documentSchema: Schema =
        Schema(id: .init("smithy.api", "Document"), type: .document, members: [
            // Since document can be a list or map of documents, among other types, it has the members for both
            // Map key/value comes first, then list member
            // Providing these members allows a map- or list-type document to be handled as any list or map would
            .init(id: .init("smithy.api", "Document", "key"), type: .string, containerType: .document),
            .init(id: .init("smithy.api", "Document", "value"), type: .document, containerType: .document),
            .init(id: .init("smithy.api", "Document", "member"), type: .document, containerType: .document),
        ])

    public static let primitiveBooleanSchema: Schema =
        Schema(id: .init("smithy.api", "PrimitiveBoolean"), type: .boolean, traits: [DefaultTrait(false)])

    public static let primitiveIntegerSchema: Schema =
        Schema(id: .init("smithy.api", "PrimitiveInteger"), type: .integer, traits: [DefaultTrait(0)])

    public static let primitiveByteSchema: Schema =
        Schema(id: .init("smithy.api", "PrimitiveByte"), type: .byte, traits: [DefaultTrait(0)])

    public static let primitiveShortSchema: Schema =
        Schema(id: .init("smithy.api", "PrimitiveShort"), type: .short, traits: [DefaultTrait(0)])

    public static let primitiveLongSchema: Schema =
        Schema(id: .init("smithy.api", "PrimitiveLong"), type: .long, traits: [DefaultTrait(0)])

    public static let primitiveFloatSchema: Schema =
        Schema(id: .init("smithy.api", "PrimitiveFloat"), type: .float, traits: [DefaultTrait(0.0)])

    public static let primitiveDoubleSchema: Schema =
        Schema(id: .init("smithy.api", "PrimitiveDouble"), type: .double, traits: [DefaultTrait(0.0)])
}
