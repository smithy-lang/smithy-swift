$version: "2.0"

namespace smithy.swift.tests.HTTPBindings

use aws.protocols#restJson1

@restJson1
service HTTPBindings {
    version: "2024-11-14"
    operations: [
        AllUnboundMembers
        AllBoundMembers
        QueryAndQueryParams
        ScalarQueryAndQueryParams
        LiteralQuery
        VerbatimLiteralQuery
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

// A list-valued `@httpQuery` binding alongside an `@httpQueryParams` map, so that the merge of
// explicit query items with query-params entries can be exercised (including name collisions).
@http(method: "GET", uri: "/QueryAndQueryParams")
operation QueryAndQueryParams {
    input: QueryAndQueryParamsInput
}

structure QueryAndQueryParamsInput {
    @httpQuery("Word")
    words: StringList

    @httpQueryParams
    params: StringMap
}

// A scalar `@httpQuery` binding alongside an `@httpQueryParams` map, for the scalar collision case.
@http(method: "GET", uri: "/ScalarQueryAndQueryParams")
operation ScalarQueryAndQueryParams {
    input: ScalarQueryAndQueryParamsInput
}

structure ScalarQueryAndQueryParamsInput {
    @httpQuery("Key")
    key: String

    @httpQueryParams
    params: StringMap
}

// Literal query string params in the `@http` URI, alongside a label, an explicit `@httpQuery`
// binding, and an `@httpQueryParams` map, so that the merge of all three sources of query items
// can be exercised.  A label is included so that the URI's query string is not confused with the
// path when labels are substituted.
@http(method: "GET", uri: "/LiteralQuery/{name}?x-id=Literal&uploads")
operation LiteralQuery {
    input: LiteralQueryInput
}

structure LiteralQueryInput {
    @httpLabel
    @required
    name: String

    @httpQuery("Word")
    words: StringList

    @httpQueryParams
    params: StringMap
}

// Literal query params whose names & values must be sent exactly as they appear in the model.
@http(method: "GET", uri: "/VerbatimLiteralQuery?plus=a+b&encoded=a%20b&flag")
operation VerbatimLiteralQuery {
    input: VerbatimLiteralQueryInput
}

structure VerbatimLiteralQueryInput {
    @httpHeader("X-A")
    a: String
}

list StringList {
    member: String
}

map StringMap {
    key: String
    value: String
}
