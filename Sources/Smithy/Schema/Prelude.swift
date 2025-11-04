//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// Below are schemas for all model shapes defined in the Smithy 2.0 prelude.
// Schemas for custom Smithy types may use these schemas in their definitions.

public var unitSchema: Schema {
    Schema(id: "smithy.api#Unit", type: .structure)
}

public var booleanSchema: Schema {
    Schema(id: "smithy.api#Boolean", type: .boolean)
}

public var stringSchema: Schema {
    Schema(id: "smithy.api#String", type: .string)
}

public var integerSchema: Schema {
    Schema(id: "smithy.api#Integer", type: .integer)
}

public var blobSchema: Schema {
    Schema(id: "smithy.api#Blob", type: .blob)
}

public var timestampSchema: Schema {
    Schema(id: "smithy.api#Timestamp", type: .timestamp)
}

public var byteSchema: Schema {
    Schema(id: "smithy.api#Byte", type: .byte)
}

public var shortSchema: Schema {
    Schema(id: "smithy.api#Short", type: .short)
}

public var longSchema: Schema {
    Schema(id: "smithy.api#Long", type: .long)
}

public var floatSchema: Schema {
    Schema(id: "smithy.api#Float", type: .float)
}

public var doubleSchema: Schema {
    Schema(id: "smithy.api#Double", type: .double)
}

public var documentSchema: Schema {
    Schema(id: "smithy.api#PrimitiveDocument", type: .document)
}

public var primitiveBooleanSchema: Schema {
    Schema(id: "smithy.api#PrimitiveBoolean", type: .boolean, traits: ["smithy.api#default": false])
}

public var primitiveIntegerSchema: Schema {
    Schema(id: "smithy.api#PrimitiveInteger", type: .integer, traits: ["smithy.api#default": 0])
}

public var primitiveByteSchema: Schema {
    Schema(id: "smithy.api#PrimitiveByte", type: .byte, traits: ["smithy.api#default": 0])
}

public var primitiveShortSchema: Schema {
    Schema(id: "smithy.api#PrimitiveShort", type: .short, traits: ["smithy.api#default": 0])
}

public var primitiveLongSchema: Schema {
    Schema(id: "smithy.api#PrimitiveLong", type: .long, traits: ["smithy.api#default": 0])
}

public var primitiveFloatSchema: Schema {
    Schema(id: "smithy.api#PrimitiveFloat", type: .float, traits: ["smithy.api#default": 0])
}

public var primitiveDoubleSchema: Schema {
    Schema(id: "smithy.api#PrimitiveDouble", type: .double, traits: ["smithy.api#default": 0])
}
