$version: "2.0"

namespace smithy.swift.tests.HTTPPayload

use aws.protocols#restJson1

@restJson1
service HTTPPayload {
    version: "2024-11-14"
    operations: [
        StructureHTTPPayload
        UnionHTTPPayload
        DocumentHTTPPayload
        StringHTTPPayload
        BlobHTTPPayload
    ]
}

@http(method: "PUT", uri: "/StructureHTTPPayload")
operation StructureHTTPPayload {
    input: StructureHTTPPayloadInput
}

structure StructureHTTPPayloadInput {
    @httpPayload
    payload: PayloadStructure
}

structure PayloadStructure {
    a: String
    b: Integer
    c: Boolean
}

@http(method: "PUT", uri: "/UnionHTTPPayload")
operation UnionHTTPPayload {
    input: UnionHTTPPayloadInput
}

structure UnionHTTPPayloadInput {
    @httpPayload
    payload: PayloadUnion
}

union PayloadUnion {
    a: String
    b: Integer
    c: Boolean
}

@http(method: "PUT", uri: "/DocumentHTTPPayload")
operation DocumentHTTPPayload {
    input: DocumentHTTPPayloadInput
}

structure DocumentHTTPPayloadInput {
    @httpPayload
    payload: Document
}

@http(method: "PUT", uri: "/StringHTTPPayload")
operation StringHTTPPayload {
    input: StringHTTPPayloadInput
}

structure StringHTTPPayloadInput {
    @httpPayload
    payload: String
}

@http(method: "PUT", uri: "/BlobHTTPPayload")
operation BlobHTTPPayload {
    input: BlobHTTPPayloadInput
}

structure BlobHTTPPayloadInput {
    @httpPayload
    payload: Blob
}
