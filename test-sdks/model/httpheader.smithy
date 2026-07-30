$version: "2.0"

namespace smithy.swift.tests.HTTPHeader

use aws.protocols#restJson1

@restJson1
service HTTPHeader {
    version: "2024-11-14"
    operations: [
        BooleanHTTPHeader
        ByteHTTPHeader
        ShortHTTPHeader
        IntegerHTTPHeader
        LongHTTPHeader
        FloatHTTPHeader
        DoubleHTTPHeader
        StringHTTPHeader
        TimestampHTTPHeader
        FormattedTimestampHTTPHeader
        StringListHTTPHeader
        IntegerListHTTPHeader
        SparseStringListHTTPHeader
        MultipleHTTPHeader
    ]
}

@http(method: "GET", uri: "/BooleanHTTPHeader")
operation BooleanHTTPHeader {
    input: BooleanHTTPHeaderInput
}

@input
structure BooleanHTTPHeaderInput {
    @httpHeader("X-Flag")
    @required
    flag: Boolean
}

@http(method: "GET", uri: "/ByteHTTPHeader")
operation ByteHTTPHeader {
    input: ByteHTTPHeaderInput
}

@input
structure ByteHTTPHeaderInput {
    @httpHeader("X-Byte")
    @required
    value: Byte
}

@http(method: "GET", uri: "/ShortHTTPHeader")
operation ShortHTTPHeader {
    input: ShortHTTPHeaderInput
}

@input
structure ShortHTTPHeaderInput {
    @httpHeader("X-Short")
    @required
    value: Short
}

@http(method: "GET", uri: "/IntegerHTTPHeader")
operation IntegerHTTPHeader {
    input: IntegerHTTPHeaderInput
}

@input
structure IntegerHTTPHeaderInput {
    @httpHeader("X-Integer")
    @required
    value: Integer
}

@http(method: "GET", uri: "/LongHTTPHeader")
operation LongHTTPHeader {
    input: LongHTTPHeaderInput
}

@input
structure LongHTTPHeaderInput {
    @httpHeader("X-Long")
    @required
    value: Long
}

@http(method: "GET", uri: "/FloatHTTPHeader")
operation FloatHTTPHeader {
    input: FloatHTTPHeaderInput
}

@input
structure FloatHTTPHeaderInput {
    @httpHeader("X-Float")
    @required
    value: Float
}

@http(method: "GET", uri: "/DoubleHTTPHeader")
operation DoubleHTTPHeader {
    input: DoubleHTTPHeaderInput
}

@input
structure DoubleHTTPHeaderInput {
    @httpHeader("X-Double")
    @required
    value: Double
}

@http(method: "GET", uri: "/StringHTTPHeader")
operation StringHTTPHeader {
    input: StringHTTPHeaderInput
}

@input
structure StringHTTPHeaderInput {
    @httpHeader("X-String")
    @required
    value: String
}

@http(method: "GET", uri: "/TimestampHTTPHeader")
operation TimestampHTTPHeader {
    input: TimestampHTTPHeaderInput
}

@input
structure TimestampHTTPHeaderInput {
    @httpHeader("X-Moment")
    @required
    moment: Timestamp
}

@http(method: "GET", uri: "/FormattedTimestampHTTPHeader")
operation FormattedTimestampHTTPHeader {
    input: FormattedTimestampHTTPHeaderInput
}

@input
structure FormattedTimestampHTTPHeaderInput {
    @httpHeader("X-Moment")
    @required
    @timestampFormat("date-time")
    moment: Timestamp
}

@http(method: "GET", uri: "/StringListHTTPHeader")
operation StringListHTTPHeader {
    input: StringListHTTPHeaderInput
}

@input
structure StringListHTTPHeaderInput {
    @httpHeader("X-Word")
    words: StringList
}

list StringList {
    member: String
}

@http(method: "GET", uri: "/IntegerListHTTPHeader")
operation IntegerListHTTPHeader {
    input: IntegerListHTTPHeaderInput
}

@input
structure IntegerListHTTPHeaderInput {
    @httpHeader("X-Number")
    numbers: IntegerList
}

list IntegerList {
    member: Integer
}

@http(method: "GET", uri: "/SparseStringListHTTPHeader")
operation SparseStringListHTTPHeader {
    input: SparseStringListHTTPHeaderInput
}

@input
structure SparseStringListHTTPHeaderInput {
    @httpHeader("X-Word")
    words: SparseStringList
}

@sparse
list SparseStringList {
    member: String
}

@http(method: "GET", uri: "/MultipleHTTPHeader")
operation MultipleHTTPHeader {
    input: MultipleHTTPHeaderInput
}

@input
structure MultipleHTTPHeaderInput {
    @httpHeader("X-Key")
    key: String

    @httpHeader("X-Count")
    count: Integer
}
