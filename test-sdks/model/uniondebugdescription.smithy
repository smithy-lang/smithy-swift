$version: "2.0"

namespace smithy.swift.tests.UnionDebugDescription

use aws.protocols#restJson1

// A non-schema-based service, so unions with sensitive content get a generated debugDescription.
@restJson1
service UnionDebugDescription {
    version: "2026-11-18"
    operations: [
        GetUnions
    ]
}

@http(method: "POST", uri: "/GetUnions")
operation GetUnions {
    input: GetUnionsInput
    output: GetUnionsOutput
}

@input
structure GetUnionsInput {
    sensitiveVariantUnion: SensitiveVariantUnion
}

@output
structure GetUnionsOutput {
    sensitiveUnion: SensitiveUnion
    unionList: UnionList
    unionMap: UnionMap
    holder: Holder
}

@sensitive
string SensitiveString

list SensitiveStringList {
    member: SensitiveString
}

map SensitiveValueMap {
    key: String
    value: SensitiveString
}

structure StructWithSensitiveMember {
    name: String
    password: SensitiveString
}

union SensitiveVariantUnion {
    plain: String
    secret: SensitiveString
    secretList: SensitiveStringList
    secretMap: SensitiveValueMap
    withStruct: StructWithSensitiveMember
}

@sensitive
union SensitiveUnion {
    a: String
    b: Integer
}

list UnionList {
    member: NestedUnion
}

map UnionMap {
    key: String
    value: NestedUnion
}

structure Holder {
    nested: NestedUnion
}

union NestedUnion {
    plain: String
    secret: SensitiveString
}
