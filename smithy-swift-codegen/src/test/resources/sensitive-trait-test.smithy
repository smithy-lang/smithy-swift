$version: "1.0"

namespace smithy.example

use aws.api#service
use aws.protocols#restJson1
use smithy.test#httpRequestTests
use smithy.test#httpResponseTests

@service(sdkId: "Rest Json Protocol")
@restJson1
service Example {
    version: "2019-12-16",
    operations: [
        SensitiveTraitInRequest,
        SensitiveTraitTestRequest
    ]
}
@http(uri: "/SensitiveTraitInRequest", method: "POST")
operation SensitiveTraitInRequest {
    input: SensitiveTraitInRequestInput,
    output: SensitiveTraitInRequestOutput
}

@http(uri: "/SensitiveTraitTestRequest", method: "POST")
operation SensitiveTraitTestRequest {
    input: SensitiveTraitTestRequestInput,
    output: SensitiveTraitTestRequestOutput
}

structure SensitiveTraitInRequestInput {
    baz: String,
    foo: String
}

@sensitive
structure SensitiveTraitInRequestOutput {
    bar: String
}

structure SensitiveTraitTestRequestInput {
   foo: String,
   bar: String,
   baz: String
}

structure SensitiveTraitTestRequestOutput {
   foo: String,
   bar: String,
   baz: String,
}
