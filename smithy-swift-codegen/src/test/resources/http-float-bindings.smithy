$version: "1.0"

namespace com.test

use aws.api#service
use aws.protocols#restJson1

@service(sdkId: "Rest Json Protocol")
@restJson1
service Example {
    version: "2019-12-16",
    operations: [
        FloatBindings
    ]
}

@readonly
@http(uri: "/FloatBindingsInput", method: "GET")
operation FloatBindings {
    input: FloatBindingsInput
}

structure FloatBindingsInput {
    @httpQuery("Float")
    queryFloat: Float,

    @httpQuery("Double")
    queryDouble: Double,

    @httpQuery("FloatList")
    queryFloatList: FloatList,

    @httpQuery("DoubleList")
    queryDoubleList: DoubleList,

    @httpQuery("String")
    queryString: String,

    @httpHeader("X-Float")
    headerFloat: Float,

    @httpHeader("X-Double")
    headerDouble: Double,

    @httpHeader("X-FloatList")
    headerFloatList: FloatList,

    @httpHeader("X-String")
    headerString: String,
}

list FloatList {
    member: Float,
}

list DoubleList {
    member: Double,
}
