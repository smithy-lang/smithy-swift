$version: "1.0"

namespace com.test

use aws.api#service
use aws.protocols#restJson1

@service(sdkId: "Rest Json Protocol")
@restJson1
service Example {
    version: "2019-12-16",
    operations: [
        QueryPrecedence
    ]
}

@readonly
@http(uri: "/QueryPrecedence", method: "GET")
operation QueryPrecedence {
    input: QueryPrecedenceInput
}

structure QueryPrecedenceInput {
    @httpQuery("bar")
    foo: String,

    @httpQueryParams
    baz: StringMap
}

map StringMap {
    key: String,
    value: String,
}