$version: "2.0"

namespace smithy.swift.tests.HTTPBindings

use aws.protocols#restJson1

@restJson1
service HTTPBindings {
    version: "2024-11-14"
    operations: [
        AllUnboundMembers
        AllBoundMembers
    ]
}

@http(method: "PUT", uri: "/AllUnboundMembers")
operation AllUnboundMembers {
    input: AllUnboundMembersInput
}

structure AllUnboundMembersInput {
    a: String
    b: Integer
    c: Boolean
}

@http(method: "PUT", uri: "/AllBoundMembers/{a}/")
operation AllBoundMembers {
    input: AllBoundMembersInput
}

structure AllBoundMembersInput {
    @httpLabel
    @required
    a: String

    @httpQuery("b")
    b: Integer

    @httpHeader("X-C")
    c: Boolean
}
