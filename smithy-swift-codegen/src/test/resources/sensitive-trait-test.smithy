$version: "1.0"

namespace com.test

use aws.api#service
use aws.protocols#restJson1
use smithy.test#httpRequestTests
use smithy.test#httpResponseTests

@service(sdkId: "Rest Json Protocol")
@restJson1
service Example {
    version: "2019-12-16",
    operations: [
        SensitiveTraitInRequest
    ]
}
@http(uri: "/SensitiveTraitInRequest", method: "POST")
operation SensitiveTraitInRequest {
    input: SensitiveTraitInRequestInput,
    output: SensitiveTraitInRequestOutput
}

structure SensitiveTraitInRequestInput {
    @sensitive
    baz: String
}

@sensitive
structure SensitiveTraitInRequestOutput {
    bar: String
}
