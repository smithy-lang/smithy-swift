$version: "2.0"

namespace smithy.swift.tests.JSONName

use aws.protocols#awsJson1_0

@awsJson1_0
service JSONName {
    version: "2022-11-30"
    operations: [
        JSONNameMembers
    ]
}

operation JSONNameMembers {
    input: JSONNameMembersInput
    output: JSONNameMembersOutput
}

structure JSONNameMembersInput {
    @jsonName("modified")
    original: String
}

structure JSONNameMembersOutput {
    @jsonName("modified")
    original: String
}
