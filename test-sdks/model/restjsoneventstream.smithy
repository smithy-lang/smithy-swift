$version: "2.0"

namespace smithy.swift.tests.RestJSONEventStream

use aws.protocols#restJson1

// A service for exercising the code-generated event stream protocol tests, using non-schema-based serde.
// The operations, and the `eventStreamTests` on them, are taken from the Smithy
// restJson1 protocol tests in the smithy-aws-protocol-tests package.
@restJson1
service RestJSONEventStream {
    version: "2026-11-10"
    operations: [
        aws.protocoltests.restjson#InputStream
        aws.protocoltests.restjson#OutputStream
        aws.protocoltests.restjson#DuplexStream
        aws.protocoltests.restjson#InputStreamWithInitialRequest
        aws.protocoltests.restjson#OutputStreamWithInitialResponse
        aws.protocoltests.restjson#DuplexStreamWithInitialMessages
    ]
}
