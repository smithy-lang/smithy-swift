$version: "1.0"
namespace com.test

use aws.protocols#awsJson1_1
use aws.auth#unsignedPayload

@awsJson1_1
service Example {
    version: "1.0.0",
    operations: [
        GetFoo,
        GetFooNoInput,
        GetFooNoOutput,
        GetFooStreamingInput,
        GetFooStreamingOutput,
        GetFooStreamingOutputNoInput,
        GetFooStreamingInputNoOutput,
        AllocateWidget,
        OperationWithDeprecatedTrait,
        UnsignedFooBlobStream,
        UnsignedFooBlobStreamWithLength,
        ExplicitBlobStreamWithLength
    ]
}

@http(method: "GET", uri: "/operationWithDeprecatedTrait")
@deprecated
operation OperationWithDeprecatedTrait {}

@http(method: "GET", uri: "/foo")
operation GetFoo {
    input: GetFooRequest,
    output: GetFooResponse,
    errors: [GetFooError]
}

structure GetFooRequest {}
structure GetFooResponse {}

@error("client")
structure GetFooError {}

@http(method: "GET", uri: "/foo-no-input")
operation GetFooNoInput {
    output: GetFooResponse
}

@http(method: "GET", uri: "/foo-no-output")
operation GetFooNoOutput {
    input: GetFooRequest
}

@streaming
blob BodyStream

structure GetFooStreamingRequest {
    body: BodyStream
}

structure GetFooStreamingResponse {
    body: BodyStream
}

@http(method: "POST", uri: "/foo-streaming-input")
operation GetFooStreamingInput {
    input: GetFooStreamingRequest,
    output: GetFooResponse
}

@http(method: "POST", uri: "/foo-streaming-output")
operation GetFooStreamingOutput {
    input: GetFooRequest,
    output: GetFooStreamingResponse
}

@http(method: "POST", uri: "/foo-streaming-output-no-input")
operation GetFooStreamingOutputNoInput {
    output: GetFooStreamingResponse
}

@http(method: "POST", uri: "/foo-streaming-input-no-output")
operation GetFooStreamingInputNoOutput {
    input: GetFooStreamingRequest
}

// https://smithy.io/2.0/spec/behavior-traits.html#idempotencytoken-trait
@documentation("This is a very cool operation.")
@http(method: "POST", uri: "/input/AllocateWidget")
operation AllocateWidget {
    input: AllocateWidgetInput
}

structure AllocateWidgetInput {
    @idempotencyToken
    clientToken: String
}

// Stream must have a known size
@streaming
@requiresLength
blob BodyStreamWithLength

@http(method: "POST", uri: "/explicit/blobstreamunsigned")
@unsignedPayload
operation UnsignedFooBlobStream {
    input: GetFooStreamingRequest,
    output: GetFooStreamingResponse
}

@http(method: "POST", uri: "/explicit/blobstreamunsignedwithlength")
@unsignedPayload
operation UnsignedFooBlobStreamWithLength {
    input: ExplicitBlobStreamWithLengthRequest,
    output: GetFooStreamingResponse
}

@http(method: "POST", uri: "/explicit/blobstreamwithlength")
operation ExplicitBlobStreamWithLength {
    input: ExplicitBlobStreamWithLengthRequest,
    output: GetFooStreamingResponse
}

structure ExplicitBlobStreamWithLengthRequest {
    @httpPayload
    payload1: BodyStreamWithLength
}