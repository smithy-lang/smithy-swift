$version: "1.0"
namespace smithy.example

use aws.protocols#restJson1

service Example {
    version: "1.0.0",
    operations: [
        PrimitiveTypes
    ]
}

@idempotent
@http(uri: "/PrimitiveTypes", method: "PUT")
operation PrimitiveTypes {
    input: PrimitiveTypesStruct,
    output: PrimitiveTypesStruct
}

structure PrimitiveTypesStruct {
    str: String,
    intVal: Integer,
    primitiveIntVal: PrimitiveInteger,
    shortVal: Short,
    primitiveShortVal: PrimitiveShort,
    longVal: Long,
    primitiveLongVal: PrimitiveLong,
    booleanVal: Boolean,
    primitiveBooleanVal: PrimitiveBoolean,
    floatVal: Float,
    primitiveFloatVal: PrimitiveFloat,
    doubleVal: Double,
    primitiveDoubleVal: PrimitiveDouble,
    byteVal: Byte,
    primitiveByteVal: PrimitiveByte
}