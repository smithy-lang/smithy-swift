
$version: "1.0"

namespace aws.protocoltests.restxml

use aws.api#service
use aws.protocols#restXml

@service(sdkId: "Rest Xml Protocol")
@restXml
service RestXml {
    version: "2019-12-16",
    operations: [
        IdempotencyTokenWithStructure
    ]
}

@httpChecksumRequired
@http(uri: "/IdempotencyTokenWithStructure", method: "PUT")
operation IdempotencyTokenWithStructure {
    input: IdempotencyToken,
}

structure IdempotencyToken {
    @idempotencyToken
    token: String,
}
