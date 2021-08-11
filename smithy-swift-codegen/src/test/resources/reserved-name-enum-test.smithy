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
    enumHeader: ReservedWordsEnum,

    metaTypeEnum: Type,

    protocolEnum: Protocol
}

structure NestedEnum {
    myEnum: ReservedWordsEnum
}

@enum([
    {
        value: "PROTOCOL",
        name: "protocol"
    },
    {
        value: "OPEN",
        name: "OPEN"
    },
    {
        value: "Self",
        name: "Self"
    },
    {
        value: "Any",
        name: "Any"
    }
])
string ReservedWordsEnum

@enum([
    {
        value: "test",
        name: "test"
    },
    {
        value: "foo",
        name: "foo"
    }
])
string Type

@enum([
    {
        value: "bar",
        name: "bar"
    },
    {
        value: "foo",
        name: "foo"
    }
])
string Protocol
