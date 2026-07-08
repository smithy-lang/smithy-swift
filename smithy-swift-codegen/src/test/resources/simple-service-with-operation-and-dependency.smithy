$version: "1.0"
namespace smithy.example

use aws.protocols#awsJson1_1
use smithy.test#httpRequestTests

@awsJson1_1
service Example {
    version: "1.0.0",
    operations: [GetFoo]
}

@httpRequestTests([
    { id: "SomeTest", protocol: "aws.protocols#restJson1", method: "GET", uri: "/" }
])
operation GetFoo {
    input: GetFooInput,
    output: GetFooOutput,
    errors: [GetFooError]
}

structure GetFooInput {
    inputString: String,
    largeInt: BigInteger,
    jsonString: Document
}
structure GetFooOutput {}

@error("client")
structure GetFooError {}
