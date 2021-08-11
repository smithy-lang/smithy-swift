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
    protocolEnum: protocol
}

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
string protocol