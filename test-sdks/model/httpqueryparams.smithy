$version: "2.0"

namespace smithy.swift.tests.HTTPQueryParams

use aws.protocols#restJson1

@restJson1
service HTTPQueryParams {
    version: "2024-11-14"
    operations: [
        StringMapHTTPQueryParams
        ListMapHTTPQueryParams
        SparseListMapHTTPQueryParams
    ]
}

@http(method: "GET", uri: "/StringMapHTTPQueryParams")
operation StringMapHTTPQueryParams {
    input: StringMapHTTPQueryParamsInput
}

@input
structure StringMapHTTPQueryParamsInput {
    @httpQueryParams
    params: StringMap
}

map StringMap {
    key: String
    value: String
}

@http(method: "GET", uri: "/ListMapHTTPQueryParams")
operation ListMapHTTPQueryParams {
    input: ListMapHTTPQueryParamsInput
}

@input
structure ListMapHTTPQueryParamsInput {
    @httpQueryParams
    params: StringListMap
}

map StringListMap {
    key: String
    value: StringList
}

list StringList {
    member: String
}

@http(method: "GET", uri: "/SparseListMapHTTPQueryParams")
operation SparseListMapHTTPQueryParams {
    input: SparseListMapHTTPQueryParamsInput
}

@input
structure SparseListMapHTTPQueryParamsInput {
    @httpQueryParams
    params: SparseStringListMap
}

map SparseStringListMap {
    key: String
    value: SparseStringList
}

@sparse
list SparseStringList {
    member: String
}
