$version: "2.0"

namespace smithy.swift.tests.EventStream

use aws.protocols#awsJson1_0

@awsJson1_0
service EventStream {
    version: "2022-11-30"
    operations: [
        EventStreamOperation
    ]
}

operation EventStreamOperation {
    input: EventStreamOperationInput
    output: EventStreamOperationOutput
    errors: [
        EventStreamOperationError
    ]
}

structure EventStreamOperationInput {
    eventStream: TestEventStream
}

structure EventStreamOperationOutput {
    eventStream: TestEventStream
}

@error("client")
structure EventStreamOperationError {
    message: String
}

@streaming
union TestEventStream {
    MessageWithBlob: MessageWithBlob
    MessageWithString: MessageWithString
    MessageWithStruct: MessageWithStruct
    MessageWithUnion: MessageWithUnion
    MessageWithHeaders: MessageWithHeaders
    MessageWithHeaderAndPayload: MessageWithHeaderAndPayload
    MessageWithNoHeaderPayloadTraits: MessageWithNoHeaderPayloadTraits
    MessageWithUnboundPayloadTraits: MessageWithUnboundPayloadTraits
    MessageWithNoMembers: MessageWithNoMembers
    EventStreamOperationError: EventStreamOperationError
}

structure MessageWithBlob {
    @eventPayload
    data: Blob
}

structure MessageWithString {
    @eventPayload
    data: String
}

structure MessageWithStruct {
    @eventPayload
    someStruct: TestStruct
}

structure MessageWithUnion {
    @eventPayload
    someUnion: TestUnion
}

structure MessageWithHeaders {
    @eventHeader
    blob: Blob

    @eventHeader
    boolean: Boolean

    @eventHeader
    byte: Byte

    @eventHeader
    int: Integer

    @eventHeader
    long: Long

    @eventHeader
    short: Short

    @eventHeader
    string: String

    @eventHeader
    timestamp: Timestamp
}

structure MessageWithHeaderAndPayload {
    @eventHeader
    header: String

    @eventPayload
    payload: Blob
}

structure MessageWithNoHeaderPayloadTraits {
    someInt: Integer
    someString: String
}

structure MessageWithUnboundPayloadTraits {
    @eventHeader
    header: String

    unboundString: String
}

structure MessageWithNoMembers {}

structure TestStruct {
    someString: String
    someInt: Integer
}

union TestUnion {
    foo: String
    bar: Integer
}
