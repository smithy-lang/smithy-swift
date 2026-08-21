$version: "2.0"

namespace smithy.swift.tests.RestJSON1Response

use aws.protocols#restJson1

// A service for exercising the RestJSON1 client protocol's deserialization of response
// and error bodies.
@restJson1
service RestJSON1Response {
    version: "2024-11-14"
    operations: [
        GetThing
    ]
}

@http(method: "POST", uri: "/GetThing")
operation GetThing {
    input: GetThingInput
    output: GetThingOutput
    errors: [
        SimpleError
        DetailedError
        RequiredMessageError
        NoMessageError
    ]
}

@input
structure GetThingInput {
    name: String
}

@output
structure GetThingOutput {
    name: String
    count: Integer
    items: StringList
}

// An error with only the conventional `message` member.
@error("client")
@httpError(400)
structure SimpleError {
    message: String
}

// An error with members beyond `message`, so that deserialization of the whole error body
// can be verified.
@error("client")
@httpError(404)
structure DetailedError {
    message: String
    resourceId: String
    attempts: Integer
}

// An error whose `message` is required, so it is pre-filled with an empty string when the
// response has no body.
@error("server")
@httpError(500)
structure RequiredMessageError {
    @required
    message: String
}

// An error with no `message` member at all.
@error("client")
@httpError(403)
structure NoMessageError {
    reason: String
}

list StringList {
    member: String
}
