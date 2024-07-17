$version: "1.0"
namespace com.test

use aws.protocols#awsJson1_1

@awsJson1_1
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
    listWithSensitiveTrait: SensitiveList
    listWithSensitiveTargetedByMember: SensitiveMemberTargetList

    mapWithSensitiveTrait: SensitiveMap
    mapWithSensitiveTargetedByKey: SensitiveKeyTargetMap
    mapWithSensitiveTargetedByValue: SensitiveValueTargetMap
    mapWithSensitiveTargetedByBoth: SensitiveTargetMap
}

@sensitive
list SensitiveList {
    member: String
}

list SensitiveMemberTargetList {
    member: SensitiveTargetStruct
}

@sensitive
map SensitiveMap {
    key: String
    value: String
}

map SensitiveKeyTargetMap {
    key: SensitiveTargetString
    value: String
}

map SensitiveValueTargetMap {
    key: String
    value: SensitiveTargetStruct
}

map SensitiveTargetMap {
    key: SensitiveTargetString
    value: SensitiveTargetStruct
}

@sensitive
structure SensitiveTargetStruct {}

@sensitive
string SensitiveTargetString