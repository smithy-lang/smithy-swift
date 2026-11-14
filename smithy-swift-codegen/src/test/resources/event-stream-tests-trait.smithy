$version: "2.0"

namespace com.test

use aws.protocols#restJson1
use smithy.test#InitialHttpRequest
use smithy.test#InitialHttpResponse
use smithy.test#eventStreamTests

@restJson1
service Example {
    version: "2026-11-10"
    operations: [
        InputStream
        OutputStream
    ]
}

@eventStreamTests([
    {
        id: "HeadersAndPayloadInput"
        documentation: "Sends an event with a header & payload."
        protocol: restJson1
        initialRequestParams: { initialMember: "foo" }
        initialRequest: {
            method: "POST"
            uri: "/InputStream"
            headers: { "initial-member": "foo" }
            forbidHeaders: ["forbidden-header"]
        }
        initialRequestShape: InitialHttpRequest
        events: [
            {
                type: "request"
                params: {
                    payloadEvent: { header: "bar", payload: { structureMember: "baz" } }
                }
                headers: {
                    ":message-type": { string: "event" }
                    header: { string: "bar" }
                    timestampHeader: { timestamp: "2024-10-31T14:15:14.5Z" }
                    blobHeader: { blob: "Zm9v" }
                    longHeader: { long: 4294967294 }
                }
                forbidHeaders: ["forbidden"]
                requireHeaders: [":event-type"]
                body: """
                    {"structureMember":"baz"}"""
                bodyMediaType: "application/json"
            }
        ]
    }
    {
        id: "ErrorEventInput"
        protocol: restJson1
        events: [
            {
                type: "request"
                params: { error: { message: "foo" } }
            }
        ]
    }
    {
        id: "FailingInput"
        documentation: "Expects any error from the SDK."
        protocol: restJson1
        events: [
            {
                type: "request"
                params: { payloadEvent: { header: "bar" } }
            }
        ]
        expectation: {
            failure: {}
        }
    }
    {
        id: "FailingWithErrorIdInput"
        documentation: "Expects a specific error from the SDK."
        protocol: restJson1
        events: [
            {
                type: "request"
                params: { payloadEvent: { header: "bar" } }
            }
        ]
        expectation: {
            failure: { errorId: ErrorEvent }
        }
    }
    {
        id: "ServerOnlyInput"
        protocol: restJson1
        events: [
            {
                type: "request"
                params: { payloadEvent: { header: "bar" } }
            }
        ]
        appliesTo: "server"
    }
])
@http(method: "POST", uri: "/InputStream")
operation InputStream {
    input := {
        @httpHeader("initial-member")
        initialMember: String

        @httpPayload
        stream: TestEventStream
    }
}

@eventStreamTests([
    {
        id: "PayloadOutput"
        protocol: restJson1
        events: [
            {
                type: "response"
                params: {
                    payloadEvent: { header: "bar", payload: { structureMember: "baz" } }
                }
                bytes: "AAAAAA=="
            }
            {
                type: "response"
                params: {
                    payloadEvent: { header: "qux" }
                }
                headers: {
                    ":message-type": { string: "event" }
                    ":event-type": { string: "payloadEvent" }
                    header: { string: "qux" }
                }
            }
        ]
    }
    {
        id: "ErrorEventOutput"
        protocol: restJson1
        events: [
            {
                type: "response"
                params: { error: { message: "foo" } }
                bytes: "AAAAAA=="
            }
        ]
    }
    {
        id: "ModeledProtocolError"
        protocol: restJson1
        initialResponse: {
            code: 500
            headers: { "X-Amzn-Errortype": "ServiceError" }
            body: """
                {"message": "foo"}"""
            bodyMediaType: "application/json"
        }
        initialResponseShape: InitialHttpResponse
        expectation: {
            failure: { errorId: ServiceError }
        }
    }
    {
        id: "InitialResponseOutput"
        protocol: restJson1
        initialResponseParams: { initialMember: "foo" }
        initialResponse: {
            code: 200
            headers: { "initial-member": "foo" }
        }
        initialResponseShape: InitialHttpResponse
    }
])
@http(method: "POST", uri: "/OutputStream")
operation OutputStream {
    output := {
        @httpHeader("initial-member")
        initialMember: String

        @httpPayload
        stream: TestEventStream
    }

    errors: [
        ServiceError
    ]
}

@streaming
union TestEventStream {
    payloadEvent: PayloadEvent
    error: ErrorEvent
}

structure PayloadEvent {
    @eventHeader
    header: String

    @eventPayload
    payload: PayloadStructure
}

structure PayloadStructure {
    structureMember: String
}

@error("client")
structure ErrorEvent {
    message: String
}

@error("server")
@httpError(500)
structure ServiceError {
    message: String
}
