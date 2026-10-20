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
        TimestampListHTTPHeader
        FormattedTimestampListHTTPHeader
        MultipleHTTPHeader
        MediaTypeHTTPHeader
        MediaTypeListHTTPHeader
        ErrorHTTPHeader
    ]
}

@http(method: "GET", uri: "/BooleanHTTPHeader")
operation BooleanHTTPHeader {
    input: BooleanHTTPHeaderInput
    output: BooleanHTTPHeaderOutput
}

@input
structure BooleanHTTPHeaderInput {
    @httpHeader("X-Flag")
    @required
    flag: Boolean
}

@output
structure BooleanHTTPHeaderOutput {
    @httpHeader("X-Flag")
    flag: Boolean
}

@http(method: "GET", uri: "/ByteHTTPHeader")
operation ByteHTTPHeader {
    input: ByteHTTPHeaderInput
    output: ByteHTTPHeaderOutput
}

@input
structure ByteHTTPHeaderInput {
    @httpHeader("X-Byte")
    @required
    value: Byte
}

@output
structure ByteHTTPHeaderOutput {
    @httpHeader("X-Byte")
    value: Byte
}

@http(method: "GET", uri: "/ShortHTTPHeader")
operation ShortHTTPHeader {
    input: ShortHTTPHeaderInput
    output: ShortHTTPHeaderOutput
}

@input
structure ShortHTTPHeaderInput {
    @httpHeader("X-Short")
    @required
    value: Short
}

@output
structure ShortHTTPHeaderOutput {
    @httpHeader("X-Short")
    value: Short
}

@http(method: "GET", uri: "/IntegerHTTPHeader")
operation IntegerHTTPHeader {
    input: IntegerHTTPHeaderInput
    output: IntegerHTTPHeaderOutput
}

@input
structure IntegerHTTPHeaderInput {
    @httpHeader("X-Integer")
    @required
    value: Integer
}

@output
structure IntegerHTTPHeaderOutput {
    @httpHeader("X-Integer")
    value: Integer
}

@http(method: "GET", uri: "/LongHTTPHeader")
operation LongHTTPHeader {
    input: LongHTTPHeaderInput
    output: LongHTTPHeaderOutput
}

@input
structure LongHTTPHeaderInput {
    @httpHeader("X-Long")
    @required
    value: Long
}

@output
structure LongHTTPHeaderOutput {
    @httpHeader("X-Long")
    value: Long
}

@http(method: "GET", uri: "/FloatHTTPHeader")
operation FloatHTTPHeader {
    input: FloatHTTPHeaderInput
    output: FloatHTTPHeaderOutput
}

@input
structure FloatHTTPHeaderInput {
    @httpHeader("X-Float")
    @required
    value: Float
}

@output
structure FloatHTTPHeaderOutput {
    @httpHeader("X-Float")
    value: Float
}

@http(method: "GET", uri: "/DoubleHTTPHeader")
operation DoubleHTTPHeader {
    input: DoubleHTTPHeaderInput
    output: DoubleHTTPHeaderOutput
}

@input
structure DoubleHTTPHeaderInput {
    @httpHeader("X-Double")
    @required
    value: Double
}

@output
structure DoubleHTTPHeaderOutput {
    @httpHeader("X-Double")
    value: Double
}

@http(method: "GET", uri: "/StringHTTPHeader")
operation StringHTTPHeader {
    input: StringHTTPHeaderInput
    output: StringHTTPHeaderOutput
}

@input
structure StringHTTPHeaderInput {
    @httpHeader("X-String")
    @required
    value: String
}

@output
structure StringHTTPHeaderOutput {
    @httpHeader("X-String")
    value: String
}

@http(method: "GET", uri: "/TimestampHTTPHeader")
operation TimestampHTTPHeader {
    input: TimestampHTTPHeaderInput
    output: TimestampHTTPHeaderOutput
}

@input
structure TimestampHTTPHeaderInput {
    @httpHeader("X-Moment")
    @required
    moment: Timestamp
}

@output
structure TimestampHTTPHeaderOutput {
    @httpHeader("X-Moment")
    moment: Timestamp
}

@http(method: "GET", uri: "/FormattedTimestampHTTPHeader")
operation FormattedTimestampHTTPHeader {
    input: FormattedTimestampHTTPHeaderInput
    output: FormattedTimestampHTTPHeaderOutput
}

@input
structure FormattedTimestampHTTPHeaderInput {
    @httpHeader("X-Moment")
    @required
    @timestampFormat("date-time")
    moment: Timestamp
}

@output
structure FormattedTimestampHTTPHeaderOutput {
    @httpHeader("X-Moment")
    @timestampFormat("date-time")
    moment: Timestamp
}

@http(method: "GET", uri: "/StringListHTTPHeader")
operation StringListHTTPHeader {
    input: StringListHTTPHeaderInput
    output: StringListHTTPHeaderOutput
}

@input
structure StringListHTTPHeaderInput {
    @httpHeader("X-Word")
    words: StringList
}

@output
structure StringListHTTPHeaderOutput {
    @httpHeader("X-Word")
    words: StringList
}

list StringList {
    member: String
}

@http(method: "GET", uri: "/IntegerListHTTPHeader")
operation IntegerListHTTPHeader {
    input: IntegerListHTTPHeaderInput
    output: IntegerListHTTPHeaderOutput
}

@input
structure IntegerListHTTPHeaderInput {
    @httpHeader("X-Number")
    numbers: IntegerList
}

@output
structure IntegerListHTTPHeaderOutput {
    @httpHeader("X-Number")
    numbers: IntegerList
}

list IntegerList {
    member: Integer
}

@http(method: "GET", uri: "/SparseStringListHTTPHeader")
operation SparseStringListHTTPHeader {
    input: SparseStringListHTTPHeaderInput
    output: SparseStringListHTTPHeaderOutput
}

@input
structure SparseStringListHTTPHeaderInput {
    @httpHeader("X-Word")
    words: SparseStringList
}

@output
structure SparseStringListHTTPHeaderOutput {
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
    output: MultipleHTTPHeaderOutput
}

@input
structure MultipleHTTPHeaderInput {
    @httpHeader("X-Key")
    key: String

    @httpHeader("X-Count")
    count: Integer
}

@output
structure MultipleHTTPHeaderOutput {
    @httpHeader("X-Key")
    key: String

    @httpHeader("X-Count")
    count: Integer

    // Not bound to a header; it is left untouched by the header deserializer.
    unbound: String
}

// Lists of timestamps are deserialized from a header by splitting on every second comma,
// since the default http-date format contains a comma of its own.  A list whose member carries
// the timestampFormat trait is split on every comma instead.
@http(method: "GET", uri: "/TimestampListHTTPHeader")
operation TimestampListHTTPHeader {
    input: TimestampListHTTPHeaderInput
    output: TimestampListHTTPHeaderOutput
}

@input
structure TimestampListHTTPHeaderInput {
    @httpHeader("X-Moment")
    moments: TimestampList
}

@output
structure TimestampListHTTPHeaderOutput {
    @httpHeader("X-Moment")
    moments: TimestampList
}

list TimestampList {
    member: Timestamp
}

@http(method: "GET", uri: "/FormattedTimestampListHTTPHeader")
operation FormattedTimestampListHTTPHeader {
    input: FormattedTimestampListHTTPHeaderInput
    output: FormattedTimestampListHTTPHeaderOutput
}

@input
structure FormattedTimestampListHTTPHeaderInput {
    @httpHeader("X-Moment")
    moments: FormattedTimestampList
}

@output
structure FormattedTimestampListHTTPHeaderOutput {
    @httpHeader("X-Moment")
    moments: FormattedTimestampList
}

list FormattedTimestampList {
    @timestampFormat("date-time")
    member: Timestamp
}

// A string that carries the mediaType trait is base64 encoded when bound to a header.
@http(method: "GET", uri: "/MediaTypeHTTPHeader")
operation MediaTypeHTTPHeader {
    input: MediaTypeHTTPHeaderInput
    output: MediaTypeHTTPHeaderOutput
}

@input
structure MediaTypeHTTPHeaderInput {
    @httpHeader("X-Json")
    @required
    value: JSONString
}

@output
structure MediaTypeHTTPHeaderOutput {
    @httpHeader("X-Json")
    value: JSONString
}

// Each element of a list of media type strings is base64 encoded on its own.
@http(method: "GET", uri: "/MediaTypeListHTTPHeader")
operation MediaTypeListHTTPHeader {
    input: MediaTypeListHTTPHeaderInput
    output: MediaTypeListHTTPHeaderOutput
}

@input
structure MediaTypeListHTTPHeaderInput {
    @httpHeader("X-Json")
    values: JSONStringList
}

@output
structure MediaTypeListHTTPHeaderOutput {
    @httpHeader("X-Json")
    values: JSONStringList
}

@mediaType("application/json")
string JSONString

list JSONStringList {
    member: JSONString
}

// An error response binds headers to the members of the error structure, same as a success response.
@http(method: "GET", uri: "/ErrorHTTPHeader")
operation ErrorHTTPHeader {
    input: ErrorHTTPHeaderInput
    output: ErrorHTTPHeaderOutput
    errors: [
        HTTPHeaderError
    ]
}

@input
structure ErrorHTTPHeaderInput {}

@output
structure ErrorHTTPHeaderOutput {}

@error("client")
@httpError(429)
structure HTTPHeaderError {
    @httpHeader("X-Key")
    key: String

    @httpHeader("X-Count")
    count: Integer

    @httpHeader("X-Word")
    words: StringList
}
