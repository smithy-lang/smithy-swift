$version: "2.0"

namespace smithy.swift.tests.HTTPPrefixHeaders

use aws.protocols#restJson1

@restJson1
service HTTPPrefixHeaders {
    version: "2024-11-14"
    operations: [
        PrefixedHTTPPrefixHeaders
        EmptyPrefixHTTPPrefixHeaders
        HeaderAndEmptyPrefixHTTPPrefixHeaders
    ]
}

// A map bound to headers under a non-empty prefix.
@http(method: "GET", uri: "/PrefixedHTTPPrefixHeaders")
operation PrefixedHTTPPrefixHeaders {
    input: PrefixedHTTPPrefixHeadersInput
    output: PrefixedHTTPPrefixHeadersOutput
}

@input
structure PrefixedHTTPPrefixHeadersInput {
    @httpPrefixHeaders("X-Foo-")
    headers: StringMap
}

@output
structure PrefixedHTTPPrefixHeadersOutput {
    @httpPrefixHeaders("X-Foo-")
    headers: StringMap
}

// A map bound to headers under an empty prefix, which binds every header.
@http(method: "GET", uri: "/EmptyPrefixHTTPPrefixHeaders")
operation EmptyPrefixHTTPPrefixHeaders {
    input: EmptyPrefixHTTPPrefixHeadersInput
    output: EmptyPrefixHTTPPrefixHeadersOutput
}

@input
structure EmptyPrefixHTTPPrefixHeadersInput {
    @httpPrefixHeaders("")
    headers: StringMap
}

@output
structure EmptyPrefixHTTPPrefixHeadersOutput {
    @httpPrefixHeaders("")
    headers: StringMap
}

// A map bound under an empty prefix alongside an `@httpHeader` binding.  An empty prefix is the only
// way the two bindings may resolve to the same header name; a non-empty prefix must not overlap with
// any `@httpHeader` binding on the same structure.
@http(method: "GET", uri: "/HeaderAndEmptyPrefixHTTPPrefixHeaders")
operation HeaderAndEmptyPrefixHTTPPrefixHeaders {
    input: HeaderAndEmptyPrefixHTTPPrefixHeadersInput
    output: HeaderAndEmptyPrefixHTTPPrefixHeadersOutput
}

@input
structure HeaderAndEmptyPrefixHTTPPrefixHeadersInput {
    @httpPrefixHeaders("")
    headers: StringMap

    @httpHeader("X-Specific")
    specific: String
}

@output
structure HeaderAndEmptyPrefixHTTPPrefixHeadersOutput {
    @httpPrefixHeaders("")
    headers: StringMap

    @httpHeader("X-Specific")
    specific: String
}

map StringMap {
    key: String
    value: String
}
