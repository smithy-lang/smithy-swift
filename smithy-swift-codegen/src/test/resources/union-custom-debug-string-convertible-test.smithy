$version: "2.0"
namespace com.test

use aws.protocols#restJson1

@restJson1
service Example {
    version: "1.0.0",
    operations: [
        GetFoo
    ]
}

@http(method: "GET", uri: "/foo")
operation GetFoo {
    input: GetFooRequest,
    output: GetFooResponse
}

structure GetFooRequest {}

structure GetFooResponse {
    sensitiveVariantUnion: SensitiveVariantUnion
    sensitiveUnion: SensitiveUnion
    unionList: UnionList
    unionMap: UnionMap
    holder: Holder
    contentBlockDeltaEvent: ContentBlockDeltaEvent
    plainUnion: PlainUnion
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
    password: SensitiveString
    name: String
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
    member: ListedUnion
}

union ListedUnion {
    plain: String
    secret: SensitiveString
}

map UnionMap {
    key: String
    value: MappedUnion
}

union MappedUnion {
    plain: String
    secret: SensitiveString
}

structure Holder {
    u: HeldUnion
}

union HeldUnion {
    plain: String
    secret: SensitiveString
}

structure ContentBlockDeltaEvent {
    delta: ContentBlockDelta
}

union ContentBlockDelta {
    text: String
    reasoningContent: ReasoningContentBlockDelta
}

@sensitive
union ReasoningContentBlockDelta {
    text: String
    signature: String
}

union PlainUnion {
    a: String
    b: Integer
}
