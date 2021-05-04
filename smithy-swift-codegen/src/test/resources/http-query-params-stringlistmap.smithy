$version: "1.0"

namespace com.test

use aws.api#service
use aws.protocols#restJson1

@service(sdkId: "Rest Json Protocol")
@restJson1
service Example {
    version: "2019-12-16",
    operations: [
        QueryParamsAsStringListMap
    ]
}

@readonly
@http(uri: "/StringListMap", method: "POST")
operation QueryParamsAsStringListMap {
    input: QueryParamsAsStringListMapInput
}

structure QueryParamsAsStringListMapInput {
    @httpQuery("corge")
    qux: String,

    @httpQueryParams
    foo: StringListMap
}

map StringListMap {
    key: String,
    value: StringList
}

list StringList {
    member: String,
}