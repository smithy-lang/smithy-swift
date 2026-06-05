$version: "2.0"

namespace smithy.swift.tests

use aws.protocols#awsJson1_0

@awsJson1_0
service AWSJSONService {
    version: "2022-11-30"
    operations: [
        JSONName
    ]
}

operation JSONName {
    input: JSONNameInput
    output: JSONNameOutput
}

structure JSONNameInput {
    @jsonName("modified")
    original: String
}

structure JSONNameOutput {
    @jsonName("modified")
    original: String
}
