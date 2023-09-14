$version: "2.0"
namespace com.test

use aws.protocols#awsJson1_1

@awsJson1_1
service Example {
    version: "1.0.0",
    operations: [
        SimpleStructure,
        DataStreaming,
        EventStreaming
    ]
}

@http(method: "PUT", uri: "/SimpleStructure")
operation SimpleStructure {
    input: Input
    output: SimpleStructureOutput
}

structure Input {}

structure SimpleStructureOutput {
    name: Name
    number: Number
}

string Name

integer Number

@http(method: "PUT", uri: "/DataStreaming")
operation DataStreaming {
    input: Input
    output: DataStreamingOutput
}

structure DataStreamingOutput {
    @required
    streamingData: StreamingData
}

@streaming
blob StreamingData

@http(method: "PUT", uri: "/EventStreaming")
operation EventStreaming {
    input: Input
    output: EventStreamingOutput
}

structure EventStreamingOutput {
    @httpLabel
    @required
    metadata: String

    @required
    eventStream: EventStream
}

@streaming
union EventStream {
    eventA: EventA
    eventB: EventB
}

structure EventA {}

structure EventB {}