$version: "1.0"
namespace com.test

use aws.protocols#restJson1
use smithy.test#httpRequestTests
use smithy.test#httpResponseTests

@restJson1
service Example {
    version: "1.0.0",
    operations: [
        NestedNestedJsonList
    ]
}

@http(method: "POST", uri: "/input/blob")
operation NestedNestedJsonList {
    input: NestedNestedJsonListInputOutput
}

structure NestedNestedJsonListInputOutput {
    nestedNestedStringList: NestedNestedStringList
}

list NestedNestedStringList {
    member: NestedStringList
}

list NestedStringList {
    member: StringList
}

list StringList {
    member: String
}