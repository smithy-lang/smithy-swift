$version: "2.0"

namespace smithy.swift.tests.EventStreamExtras

use aws.protocols#restJson1
use smithy.test#InitialHttpRequest
use smithy.test#eventStreamTests

// Event stream protocol tests for cases that the upstream restJson1 tests don't cover.
// These operations are included in the RestJSONEventStream test SDKs.
@eventStreamTests([
    {
        id: "EnumPayloadInput"
        documentation: "An enum bound to the event payload is written as its raw value, as text."
        protocol: restJson1
        events: [
            {
                type: "request"
                params: {
                    enumPayload: { payload: "bar" }
                }
                headers: {
                    ":message-type": { string: "event" }
                    ":event-type": { string: "enumPayload" }
                    ":content-type": { string: "text/plain" }
                }
                body: "bar"
                bodyMediaType: "text/plain"
            }
        ]
    }
    {
        id: "EnumPayloadOutput"
        documentation: "An enum bound to the event payload is read from its raw value, as text."
        protocol: restJson1
        events: [
            {
                type: "response"
                params: {
                    enumPayload: { payload: "bar" }
                }
                headers: {
                    ":message-type": { string: "event" }
                    ":event-type": { string: "enumPayload" }
                    ":content-type": { string: "text/plain" }
                }
                body: "bar"
                bodyMediaType: "text/plain"
            }
        ]
    }
])
@http(method: "POST", uri: "/EnumPayloadStream")
operation EnumPayloadStream {
    input := {
        @httpPayload
        stream: EnumPayloadEventStream
    }

    output := {
        @httpPayload
        stream: EnumPayloadEventStream
    }
}

@streaming
union EnumPayloadEventStream {
    enumPayload: EnumPayloadEvent
}

structure EnumPayloadEvent {
    @eventPayload
    payload: PayloadEnum
}

enum PayloadEnum {
    FOO = "foo"
    BAR = "bar"
}

@eventStreamTests([
    {
        id: "InitialRequestHostAndBody"
        documentation: "The initial request is sent to the configured host, with the input's body members as its body."
        protocol: restJson1
        initialRequestParams: { bodyMember: "foo" }
        initialRequest: {
            method: "POST"
            uri: "/InitialRequestFields"
            host: "custom.example.com"
            resolvedHost: "custom.example.com"
            body: """
                {"bodyMember":"foo"}"""
            bodyMediaType: "application/json"
        }
        initialRequestShape: InitialHttpRequest
    }
])
@http(method: "POST", uri: "/InitialRequestFields")
operation InitialRequestFields {
    input := {
        bodyMember: String
    }

    output := {
        @httpPayload
        stream: EnumPayloadEventStream
    }
}
