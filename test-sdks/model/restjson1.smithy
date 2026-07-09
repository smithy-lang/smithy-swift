$version: "2.0"

namespace smithy.swift.restJson1Tests

use aws.protocols#restJson1

@restJson1
service RestJSON1Service {
    version: "2022-11-30"
    operations: [
        BooleanHTTPLabel
        IntegerHTTPLabel
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
