$version: "2.0"

namespace smithy.swift.restJson1Tests

use aws.protocols#restJson1

@restJson1
service RestJSON1Service {
    version: "2022-11-30"
    operations: [
        GetWidget
    ]
}

@http(method: "GET", uri: "/{tidbit}")
operation GetWidget {
    input: GetWidgetInput
    output: GetWidgetOutput
}

@input
structure GetWidgetInput {
    @httpLabel
    @required
    tidbit: String
}

@output
structure GetWidgetOutput {}
