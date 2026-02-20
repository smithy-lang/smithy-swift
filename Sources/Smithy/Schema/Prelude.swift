//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// Below are schemas for all model shapes defined in the Smithy 2.0 prelude.
// Schemas for custom Smithy types may use these schemas in their definitions.

public enum Prelude {

    public static var unitSchema: Schema {
        Schema(id: .init("smithy.api", "Unit"), type: .structure, traits: [UnitTypeTrait()])
    }

    public static var booleanSchema: Schema {
        Schema(id: .init("smithy.api", "Boolean"), type: .boolean)
    }

    public static var stringSchema: Schema {
        Schema(id: .init("smithy.api", "String"), type: .string)
    }

    public static var integerSchema: Schema {
        Schema(id: .init("smithy.api", "Integer"), type: .integer)
    }

    public static var blobSchema: Schema {
        Schema(id: .init("smithy.api", "Blob"), type: .blob)
    }

    public static var timestampSchema: Schema {
        Schema(id: .init("smithy.api", "Timestamp"), type: .timestamp)
    }

    public static var byteSchema: Schema {
        Schema(id: .init("smithy.api", "Byte"), type: .byte)
    }

    public static var shortSchema: Schema {
        Schema(id: .init("smithy.api", "Short"), type: .short)
    }

    public static var longSchema: Schema {
        Schema(id: .init("smithy.api", "Long"), type: .long)
    }

    public static var floatSchema: Schema {
        Schema(id: .init("smithy.api", "Float"), type: .float)
    }

    public static var doubleSchema: Schema {
        Schema(id: .init("smithy.api", "Double"), type: .double)
    }

    public static var bigIntegerSchema: Schema {
        Schema(id: .init("smithy.api", "BigInteger"), type: .bigInteger)
    }

    public static var bigDecimalSchema: Schema {
        Schema(id: .init("smithy.api", "BigDecimal"), type: .bigDecimal)
    }

    public static var documentSchema: Schema {
        Schema(id: .init("smithy.api", "Document"), type: .document)
    }

    public static var primitiveBooleanSchema: Schema {
        Schema(id: .init("smithy.api", "PrimitiveBoolean"), type: .boolean, traits: [DefaultTrait(false)])
    }

    public static var primitiveIntegerSchema: Schema {
        Schema(id: .init("smithy.api", "PrimitiveInteger"), type: .integer, traits: [DefaultTrait(0)])
    }

    public static var primitiveByteSchema: Schema {
        Schema(id: .init("smithy.api", "PrimitiveByte"), type: .byte, traits: [DefaultTrait(0)])
    }

    public static var primitiveShortSchema: Schema {
        Schema(id: .init("smithy.api", "PrimitiveShort"), type: .short, traits: [DefaultTrait(0)])
    }

    public static var primitiveLongSchema: Schema {
        Schema(id: .init("smithy.api", "PrimitiveLong"), type: .long, traits: [DefaultTrait(0)])
    }

    public static var primitiveFloatSchema: Schema {
        Schema(id: .init("smithy.api", "PrimitiveFloat"), type: .float, traits: [DefaultTrait(0.0)])
    }

    public static var primitiveDoubleSchema: Schema {
        Schema(id: .init("smithy.api", "PrimitiveDouble"), type: .double, traits: [DefaultTrait(0.0)])
    }

    // The following schemas aren't strictly part of Smithy's prelude, but are used when deserializing a
    // list or map contained in a Smithy document.

    public static var listDocumentSchema: Schema {
        Schema(id: .init("swift.synthetic", "ListDocument"), type: .list, members: [
            .init(id: .init("swift.synthetic", "ListDocument", "member"), type: .document),
        ])
    }

    public static var mapDocumentSchema: Schema {
        Schema(id: .init("swift.synthetic", "MapDocument"), type: .list, members: [
            .init(id: .init("swift.synthetic", "MapDocument", "key"), type: .string),
            .init(id: .init("swift.synthetic", "MapDocument", "value"), type: .document),
        ])
    }
}
