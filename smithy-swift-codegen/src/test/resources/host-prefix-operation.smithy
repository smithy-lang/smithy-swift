namespace com.test
use aws.protocols#awsJson1_1
@awsJson1_1
service Example {
    version: "1.0.0",
    operations: [ GetStatus ]
}
@readonly
@endpoint(hostPrefix: "{foo}.data.")
@http(method: "POST", uri: "/status")
operation GetStatus {
    input: GetStatusInput,
    output: GetStatusOutput
}
structure GetStatusInput {
    @required
    @hostLabel
    foo: String
}

structure GetStatusOutput {}