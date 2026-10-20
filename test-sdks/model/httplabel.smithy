$version: "2.0"

namespace smithy.swift.tests.HTTPLabel

use aws.protocols#restJson1

@restJson1
service HTTPLabel {
    version: "2022-11-30"
    operations: [
        BooleanHTTPLabel
        ByteHTTPLabel
        ShortHTTPLabel
        IntegerHTTPLabel
        LongHTTPLabel
        FloatHTTPLabel
        DoubleHTTPLabel
        StringHTTPLabel
        GreedyStringHTTPLabel
        TimestampHTTPLabel
        FormattedTimestampHTTPLabel
    ]
}

@http(method: "GET", uri: "/boolean/{answer}")
operation BooleanHTTPLabel {
    input: BooleanHTTPLabelInput
}

@input
structure BooleanHTTPLabelInput {
    @httpLabel
    @required
    answer: Boolean
}

@http(method: "GET", uri: "/byte/{quantity}")
operation ByteHTTPLabel {
    input: ByteHTTPLabelInput
}

@input
structure ByteHTTPLabelInput {
    @httpLabel
    @required
    quantity: Byte
}

@http(method: "GET", uri: "/short/{quantity}")
operation ShortHTTPLabel {
    input: ShortHTTPLabelInput
}

@input
structure ShortHTTPLabelInput {
    @httpLabel
    @required
    quantity: Short
}

@http(method: "GET", uri: "/integer/{quantity}")
operation IntegerHTTPLabel {
    input: IntegerHTTPLabelInput
}

@input
structure IntegerHTTPLabelInput {
    @httpLabel
    @required
    quantity: Integer
}

@http(method: "GET", uri: "/long/{quantity}")
operation LongHTTPLabel {
    input: LongHTTPLabelInput
}

@input
structure LongHTTPLabelInput {
    @httpLabel
    @required
    quantity: Long
}

@http(method: "GET", uri: "/float/{quantity}")
operation FloatHTTPLabel {
    input: FloatHTTPLabelInput
}

@input
structure FloatHTTPLabelInput {
    @httpLabel
    @required
    quantity: Float
}

@http(method: "GET", uri: "/double/{quantity}")
operation DoubleHTTPLabel {
    input: DoubleHTTPLabelInput
}

@input
structure DoubleHTTPLabelInput {
    @httpLabel
    @required
    quantity: Double
}

@http(method: "GET", uri: "/string/{word}")
operation StringHTTPLabel {
    input: StringHTTPLabelInput
}

@input
structure StringHTTPLabelInput {
    @httpLabel
    @required
    word: String
}

@http(method: "GET", uri: "/greedyString/{word+}")
operation GreedyStringHTTPLabel {
    input: GreedyStringHTTPLabelInput
}

@input
structure GreedyStringHTTPLabelInput {
    @httpLabel
    @required
    word: String
}

@http(method: "GET", uri: "/timestamp/{moment}")
operation TimestampHTTPLabel {
    input: TimestampHTTPLabelInput
}

@input
structure TimestampHTTPLabelInput {
    @httpLabel
    @required
    moment: Timestamp
}

@http(method: "GET", uri: "/formattedTimestamp/{moment}")
operation FormattedTimestampHTTPLabel {
    input: FormattedTimestampHTTPLabelInput
}

@input
structure FormattedTimestampHTTPLabelInput {
    @httpLabel
    @required
    @timestampFormat("http-date")
    moment: Timestamp
}
