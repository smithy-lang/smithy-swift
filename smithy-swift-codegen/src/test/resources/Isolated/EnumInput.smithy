$version: "1.0"
namespace com.test

use aws.protocols#restJson1
use smithy.test#httpRequestTests
use smithy.test#httpResponseTests

@restJson1
service Example {
    version: "1.0.0",
    operations: [
            EnumInput
    ]
}

@http(method: "POST", uri: "/input/enum")
operation EnumInput {
    input: EnumInputRequest
}

structure EnumInputRequest {
    nestedWithEnum: NestedEnum,

    @httpHeader("X-EnumHeader")
    enumHeader: MyEnum
}

structure NestedEnum {
    myEnum: MyEnum
}

@enum([
    {
        value: "rawValue1",
        name: "Variant1"
    },
    {
        value: "rawValue2",
        name: "Variant2"
    }
])
string MyEnum