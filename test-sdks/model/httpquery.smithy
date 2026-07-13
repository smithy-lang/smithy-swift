$version: "2.0"

namespace smithy.swift.tests.HTTPQuery

use aws.protocols#restJson1

@restJson1
service HTTPQuery {
    version: "2024-11-14"
    operations: [
        BooleanHTTPQuery
        ByteHTTPQuery
        ShortHTTPQuery
        IntegerHTTPQuery
        LongHTTPQuery
        FloatHTTPQuery
        DoubleHTTPQuery
        StringHTTPQuery
        TimestampHTTPQuery
        FormattedTimestampHTTPQuery
        StringListHTTPQuery
        SparseStringListHTTPQuery
        EncodedNameHTTPQuery
        MultipleHTTPQuery
    ]
}

@http(method: "GET", uri: "/BooleanHTTPQuery")
operation BooleanHTTPQuery {
    input: BooleanHTTPQueryInput
}

@input
structure BooleanHTTPQueryInput {
    @httpQuery("Flag")
    @required
    flag: Boolean
}

@http(method: "GET", uri: "/ByteHTTPQuery")
operation ByteHTTPQuery {
    input: ByteHTTPQueryInput
}

@input
structure ByteHTTPQueryInput {
    @httpQuery("Byte")
    @required
    value: Byte
}

@http(method: "GET", uri: "/ShortHTTPQuery")
operation ShortHTTPQuery {
    input: ShortHTTPQueryInput
}

@input
structure ShortHTTPQueryInput {
    @httpQuery("Short")
    @required
    value: Short
}

@http(method: "GET", uri: "/IntegerHTTPQuery")
operation IntegerHTTPQuery {
    input: IntegerHTTPQueryInput
}

@input
structure IntegerHTTPQueryInput {
    @httpQuery("Integer")
    @required
    value: Integer
}

@http(method: "GET", uri: "/LongHTTPQuery")
operation LongHTTPQuery {
    input: LongHTTPQueryInput
}

@input
structure LongHTTPQueryInput {
    @httpQuery("Long")
    @required
    value: Long
}

@http(method: "GET", uri: "/FloatHTTPQuery")
operation FloatHTTPQuery {
    input: FloatHTTPQueryInput
}

@input
structure FloatHTTPQueryInput {
    @httpQuery("Float")
    @required
    value: Float
}

@http(method: "GET", uri: "/DoubleHTTPQuery")
operation DoubleHTTPQuery {
    input: DoubleHTTPQueryInput
}

@input
structure DoubleHTTPQueryInput {
    @httpQuery("Double")
    @required
    value: Double
}

@http(method: "GET", uri: "/StringHTTPQuery")
operation StringHTTPQuery {
    input: StringHTTPQueryInput
}

@input
structure StringHTTPQueryInput {
    @httpQuery("String")
    @required
    value: String
}

@http(method: "GET", uri: "/TimestampHTTPQuery")
operation TimestampHTTPQuery {
    input: TimestampHTTPQueryInput
}

@input
structure TimestampHTTPQueryInput {
    @httpQuery("Moment")
    @required
    moment: Timestamp
}

@http(method: "GET", uri: "/FormattedTimestampHTTPQuery")
operation FormattedTimestampHTTPQuery {
    input: FormattedTimestampHTTPQueryInput
}

@input
structure FormattedTimestampHTTPQueryInput {
    @httpQuery("Moment")
    @required
    @timestampFormat("http-date")
    moment: Timestamp
}

@http(method: "GET", uri: "/StringListHTTPQuery")
operation StringListHTTPQuery {
    input: StringListHTTPQueryInput
}

@input
structure StringListHTTPQueryInput {
    @httpQuery("Word")
    words: StringList
}

list StringList {
    member: String
}

@http(method: "GET", uri: "/SparseStringListHTTPQuery")
operation SparseStringListHTTPQuery {
    input: SparseStringListHTTPQueryInput
}

@input
structure SparseStringListHTTPQueryInput {
    @httpQuery("Word")
    words: SparseStringList
}

@sparse
list SparseStringList {
    member: String
}

@http(method: "GET", uri: "/EncodedNameHTTPQuery")
operation EncodedNameHTTPQuery {
    input: EncodedNameHTTPQueryInput
}

@input
structure EncodedNameHTTPQueryInput {
    @httpQuery("name with spaces")
    @required
    value: String
}

@http(method: "GET", uri: "/MultipleHTTPQuery")
operation MultipleHTTPQuery {
    input: MultipleHTTPQueryInput
}

@input
structure MultipleHTTPQueryInput {
    @httpQuery("Key")
    key: String

    @httpQuery("Count")
    count: Integer
}
