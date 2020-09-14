$version: "1.0"
namespace com.test

use aws.protocols#restJson1
use smithy.test#httpRequestTests

@restJson1
service Example {
    version: "1.0.0",
    operations: [
        SmokeTest,
        DuplicateInputTest,
        ExplicitString,
        ExplicitBlob,
        ExplicitBlobStream,
        ExplicitStruct,
        ListInput,
        MapInput,
        EnumInput,
        TimestampInput,
        BlobInput,
        EmptyInputAndEmptyOutput,
        SimpleScalarProperties,
        StreamingTraits,
        HttpPrefixHeaders
    ]
}

@http(method: "POST", uri: "/smoketest/{label1}/foo")
operation SmokeTest {
    input: SmokeTestRequest,
    output: SmokeTestResponse,
    errors: [SmokeTestError]
}

@http(method: "POST", uri: "/smoketest-duplicate/{label1}/foo")
operation DuplicateInputTest {
    // uses the same input type as another operation. Ensure that we only generate one instance of the serializer
    input: SmokeTestRequest
}

structure SmokeTestRequest {
    @httpHeader("X-Header1")
    header1: String,

    @httpHeader("X-Header2")
    header2: String,

    @httpQuery("Query1")
    query1: String,

    @required
    @httpLabel
    label1: String,

    payload1: String,
    payload2: Integer,
    payload3: Nested
}

apply SmokeTest @httpRequestTests([
    {
        id: "SmokeTest",
        documentation: "Serializes a smoke test request with body, headers, query params, and labels",
        protocol: restJson1,
        method: "POST",
        uri: "/smoketest/{label1}/foo",
        body: """
        {
        "payload1": "String",
        "payload2": 2,
        "payload3": {
            "member1": "test string",
            "member2": "test string 2"
            }
        }""",
        headers: {
            "X-Header1": "Foo",
            "X-Header2": "Bar"
        },
        requireHeaders: [
            "Content-Length"
        ],
        queryParams: [
        "Query1=Query 1"
        ],
        params: {
            label1: "label",
            query1: "Query 1",
            header1: "Foo",
            header2: "Bar",
            payload1: "String",
            payload2: 2,
            payload3: {
                member1: "test string",
                member2: "test string 2"
            }
        }
    }
])

structure Nested {
    member1: String,
    member2: String
}

structure SmokeTestResponse {

}

@error("client")
structure SmokeTestError {}


@http(method: "POST", uri: "/explicit/string")
operation ExplicitString {
    input: ExplicitStringRequest
}

structure ExplicitStringRequest {
    @httpPayload
    payload1: String
}

apply ExplicitString @httpRequestTests([
    {
        id: "ExplicitString",
        documentation: "Serializes a request with an explicit string payload",
        protocol: restJson1,
        method: "POST",
        uri: "/explicit/string",
        body: """
        {
        "payload1": "explicit string"
        }""",
        headers: {},
        requireHeaders: [
            "Content-Length"
        ],
        queryParams: [],
        params: {
        payload1: "explicit string"
        }
    }
])

@http(method: "POST", uri: "/explicit/blob")
operation ExplicitBlob {
    input: ExplicitBlobRequest
}

structure ExplicitBlobRequest {
    @httpPayload
    payload1: Blob
}

@streaming
blob BodyStream

@http(method: "POST", uri: "/explicit/blobstream")
operation ExplicitBlobStream {
    input: ExplicitBlobStreamRequest
}

structure ExplicitBlobStreamRequest {
    @httpPayload
    payload1: BodyStream
}

@http(method: "POST", uri: "/explicit/struct")
operation ExplicitStruct {
    input: ExplicitStructRequest
}

structure Nested4 {
    member1: Integer,
    // sanity check, member serialization for non top-level (bound to the operation input) aggregate shapes
    intList: IntList,
    intMap: IntMap
}

structure Nested3 {
    member1: String,
    member2: String,
    member3: Nested4
}

structure Nested2 {
    moreNesting: Nested3
}

structure ExplicitStructRequest {
    @httpPayload
    payload1: Nested2
}

list IntList {
    member: Integer
}

list StructList {
    member: Nested
}

// A list of lists of integers
list NestedIntList {
    member: IntList
}

// A list of enums
list EnumList {
    member: MyEnum
}

list BlobList {
    member: Blob
}

@http(method: "POST", uri: "/input/list")
operation ListInput {
    input: ListInputRequest
}

structure ListInputRequest {
    enumList: EnumList,
    intList: IntList,
    structList: StructList,
    nestedIntList: NestedIntList,
    blobList: BlobList
}

map IntMap {
    key: String,
    value: Integer
}

// only exists as value of a map through MapInputRequest::structMap
structure ReachableOnlyThroughMap {
    prop1: Integer
}

map StructMap {
    key: String,
    value: ReachableOnlyThroughMap
}

map EnumMap {
    key: String,
    value: MyEnum
}

map BlobMap {
    key: String,
    value: Blob
}

map DateMap {
    key: String,
    @timestampFormat("http-date")
    value: Timestamp
}

@http(method: "POST", uri: "/input/map")
operation MapInput {
    input: MapInputRequest
}

structure MapInputRequest {
    intMap: IntMap,
    structMap: StructMap,
    enumMap: EnumMap,
    blobMap: BlobMap,
    dateMap: DateMap
}


@http(method: "POST", uri: "/input/enum")
operation EnumInput {
    input: EnumInputRequest
}

@enum([
    {
        value: "rawValue1",
        name: "Variant1"
    },
    {
        value: "rawValue2",
        name: "Variant2"
    }
])
string MyEnum

structure NestedEnum {
    myEnum: MyEnum
}

structure EnumInputRequest {
    nestedWithEnum: NestedEnum,

    @httpHeader("X-EnumHeader")
    enumHeader: MyEnum
}

@http(method: "POST", uri: "/input/timestamp/{tsLabel}")
operation TimestampInput {
    input: TimestampInputRequest
}

list TimestampList {
    member: Timestamp
}

structure TimestampInputRequest {
    // (protocol default)
    normal: Timestamp,

    @timestampFormat("date-time")
    dateTime: Timestamp,

    @timestampFormat("epoch-seconds")
    epochSeconds: Timestamp,

    @timestampFormat("http-date")
    httpDate: Timestamp,

    timestampList: TimestampList,

    @httpHeader("X-Date")
    @timestampFormat("http-date")
    headerHttpDate: Timestamp,

    @httpHeader("X-Epoch")
    @timestampFormat("epoch-seconds")
    headerEpoch: Timestamp,

    @httpQuery("qtime")
    @timestampFormat("date-time")
    queryTimestamp: Timestamp,

    @httpQuery("qtimeList")
    queryTimestampList: TimestampList,

    @required
    @httpLabel
    tsLabel: Timestamp
}

@http(method: "POST", uri: "/input/blob")
operation BlobInput {
    input: BlobInputRequest
}

@mediaType("video/quicktime")
string MyMediaHeader

structure BlobInputRequest {
    // smithy spec doesn't allow blobs for headers but strings with media type are also base64 encoded
    @httpHeader("X-Blob")
    headerMediaType: MyMediaHeader,

    @httpQuery("qblob")
    queryBlob: Blob,

    payloadBlob: Blob
}

structure EmptyInputAndEmptyOutputInput {}
structure EmptyInputAndEmptyOutputOutput {}

@http(uri: "/EmptyInputAndEmptyOutput", method: "POST")
operation EmptyInputAndEmptyOutput {
    input: EmptyInputAndEmptyOutputInput,
    output: EmptyInputAndEmptyOutputOutput
}

apply EmptyInputAndEmptyOutput @httpRequestTests([
    {
        id: "RestJsonEmptyInputAndEmptyOutput",
        documentation: "Empty input serializes no payload",
        protocol: restJson1,
        method: "POST",
        uri: "/EmptyInputAndEmptyOutput",
        body: "",
        bodyMediaType: "application/json"
    }
])

structure SimpleScalarPropertiesInputOutput {
    @httpHeader("X-Foo")
    foo: String,

    stringValue: String,
    trueBooleanValue: Boolean,
    falseBooleanValue: Boolean,
    byteValue: Byte,
    shortValue: Short,
    integerValue: Integer,
    longValue: Long,
    floatValue: Float,

    @jsonName("DoubleDribble")
    doubleValue: Double,
}

@idempotent
@http(uri: "/SimpleScalarProperties", method: "PUT")
operation SimpleScalarProperties {
    input: SimpleScalarPropertiesInputOutput,
    output: SimpleScalarPropertiesInputOutput
}

apply SimpleScalarProperties @httpRequestTests([
    {
        id: "RestJsonDoesntSerializeNullStructureValues",
        documentation: "Rest Json should not serialize null structure values",
        protocol: restJson1,
        method: "PUT",
        uri: "/SimpleScalarProperties",
        body: "{}",
        headers: {
            "Content-Type": "application/json",
        },
        params: {
            stringValue: null
        },
    },
])

@http(uri: "/StreamingTraits", method: "POST")
operation StreamingTraits {
    input: StreamingTraitsInputOutput,
    output: StreamingTraitsInputOutput
}

apply StreamingTraits @httpRequestTests([
    {
        id: "RestJsonStreamingTraitsWithBlob",
        documentation: "Serializes a blob in the HTTP payload",
        protocol: restJson1,
        method: "POST",
        uri: "/StreamingTraits",
        body: "blobby blob blob",
        headers: {
            "X-Foo": "Foo",
            "Content-Type": "application/octet-stream"
        },
        params: {
            foo: "Foo",
            blob: "blobby blob blob"
        }
    },
    {
        id: "RestJsonStreamingTraitsWithNoBlobBody",
        documentation: "Serializes an empty blob in the HTTP payload",
        protocol: restJson1,
        method: "POST",
        uri: "/StreamingTraits",
        body: "",
        headers: {
            "X-Foo": "Foo"
        },
        params: {
            foo: "Foo"
        }
    },
])

structure StreamingTraitsInputOutput {
    @httpHeader("X-Foo")
    foo: String,

    @httpPayload
    blob: StreamingBlob,
}

@streaming
blob StreamingBlob

@readonly
@http(uri: "/HttpPrefixHeaders", method: "GET")
@externalDocumentation("httpPrefixHeaders Trait": "https://awslabs.github.io/smithy/1.0/spec/http.html#httpprefixheaders-trait")
operation HttpPrefixHeaders  {
    input: HttpPrefixHeadersInputOutput,
    output: HttpPrefixHeadersInputOutput
}

apply HttpPrefixHeaders @httpRequestTests([
    {
        id: "RestJsonHttpPrefixHeadersAreNotPresent",
        documentation: "No prefix headers are serialized because the value is empty",
        protocol: restJson1,
        method: "GET",
        uri: "/HttpPrefixHeaders",
        body: "",
        headers: {
            "X-Foo": "Foo"
        },
        params: {
            foo: "Foo",
            fooMap: {}
        }
    },
])

structure HttpPrefixHeadersInputOutput {
    @httpHeader("X-Foo")
    foo: String,

    @httpPrefixHeaders("X-Foo-")
    fooMap: StringMap
}

map StringMap {
    key: String,
    value: String
}