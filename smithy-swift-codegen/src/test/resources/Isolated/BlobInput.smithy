$version: "1.0"
namespace com.test

use aws.protocols#restJson1
use smithy.test#httpRequestTests
use smithy.test#httpResponseTests

@restJson1
service Example {
    version: "1.0.0",
    operations: [
            BlobInput
    ]
}

@http(method: "POST", uri: "/input/blob")
operation BlobInput {
    input: BlobInputRequest
}

structure BlobInputRequest {
    // smithy spec doesn't allow blobs for headers but strings with media type are also base64 encoded
    @httpHeader("X-Blob")
    headerMediaType: MyMediaHeader,

    payloadBlob: Blob
}


@mediaType("video/quicktime")
string MyMediaHeader

@streaming
blob BodyStream