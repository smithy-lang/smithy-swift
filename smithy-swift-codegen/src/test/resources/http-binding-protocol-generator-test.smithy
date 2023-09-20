$version: "1.0"
namespace com.test

use aws.protocols#restJson1
use smithy.test#httpRequestTests
use smithy.test#httpResponseTests

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
        IndirectEnumOperation,
        TimestampInput,
        BlobInput,
        EmptyInputAndEmptyOutput,
        SimpleScalarProperties,
        StreamingTraits,
        HttpPrefixHeaders,
        RecursiveShapes,
        JsonUnions,
        NestedShapes,
        GreetingWithErrors,
        JsonLists,
        HttpResponseCode,
        JsonMaps,
        PrimitiveTypes,
        QueryIdempotencyTokenAutoFill,
        IdempotencyTokenWithHttpHeader,
        IdempotencyTokenWithHttpPayloadTraitOnToken,
        IdempotencyTokenWithoutHttpPayloadTraitOnAnyMember,
        IdempotencyTokenWithoutHttpPayloadTraitOnToken,
        InlineDocument,
        InlineDocumentAsPayload,
        RequiredHttpFields,
        PublishMessagesInitialRequest,
        PublishMessagesNoInitialRequest
    ]
}

@http(uri: "/QueryIdempotencyTokenAutoFill", method: "POST")
@tags(["client-only"])
operation QueryIdempotencyTokenAutoFill {
    input: QueryIdempotencyTokenAutoFillInput
}

@http(uri: "/IdempotencyTokenWithHttpHeader", method: "POST")
@tags(["client-only"])
operation IdempotencyTokenWithHttpHeader {
    input: IdempotencyTokenWithHttpHeaderInput
}

@http(uri: "/IdempotencyTokenWithHttpPayloadTraitOnToken", method: "POST")
@tags(["client-only"])
operation IdempotencyTokenWithHttpPayloadTraitOnToken {
    input: IdempotencyTokenWithHttpPayloadTraitOnTokenInput
}

@http(uri: "/IdempotencyTokenWithoutHttpPayloadTraitOnAnyMember", method: "POST")
@tags(["client-only"])
operation IdempotencyTokenWithoutHttpPayloadTraitOnAnyMember {
    input: IdempotencyTokenWithoutHttpPayloadTraitOnAnyMemberInput
}

@http(uri: "/IdempotencyTokenWithoutHttpPayloadTraitOnToken", method: "POST")
@tags(["client-only"])
operation IdempotencyTokenWithoutHttpPayloadTraitOnToken {
    input: IdempotencyTokenWithoutHttpPayloadTraitOnTokenInput
}

@idempotent
@http(uri: "/PrimitiveTypes", method: "PUT")
operation PrimitiveTypes {
    input: PrimitiveTypesStruct,
    output: PrimitiveTypesStruct
}

@idempotent
@http(uri: "/JsonLists", method: "PUT")
operation JsonLists {
    input: JsonListsInputOutput,
    output: JsonListsInputOutput
}

@http(uri: "/JsonMaps", method: "POST")
operation JsonMaps {
    input: JsonMapsInputOutput,
    output: JsonMapsInputOutput
}

//Nested aggregate shapes
@http(uri: "/NestedShapes", method: "PUT")
operation NestedShapes {
    input: NestedShapesInputOutput,
    output: NestedShapesInputOutput
}

/// This example serializes an inline document as part of the payload.
@idempotent
@http(uri: "/InlineDocument", method: "PUT")
operation InlineDocument {
    input: InlineDocumentInputOutput,
    output: InlineDocumentInputOutput
}

/// This example serializes an inline document as the entire HTTP payload.
@idempotent
@http(uri: "/InlineDocumentAsPayload", method: "PUT")
operation InlineDocumentAsPayload {
    input: InlineDocumentAsPayloadInputOutput,
    output: InlineDocumentAsPayloadInputOutput
}

structure InlineDocumentAsPayloadInputOutput {
    @httpPayload
    documentValue: Document,
}

structure InlineDocumentInputOutput {
    stringValue: String,
    documentValue: Document,
}

structure NestedShapesInputOutput {
    nestedListInDict: NestedListInDict,
    nestedDictInList: NestedDictInList,
    nestedListOfListInDict: NestedListOfListInDict
}

map NestedListInDict {
   key: String,
   value: TimestampList
}

list NestedDictInList {
    member: StringMap
}

map NestedListOfListInDict {
    key: String,
    value: NestedLongList
}

/// Recursive shapes
@idempotent
@http(uri: "/RecursiveShapes", method: "PUT")
operation RecursiveShapes {
    input: RecursiveShapesInputOutput,
    output: RecursiveShapesInputOutput
}

apply RecursiveShapes @httpRequestTests([
    {
        id: "RestJsonRecursiveShapes",
        documentation: "Serializes recursive structures",
        protocol: restJson1,
        method: "PUT",
        uri: "/RecursiveShapes",
        body: """
              {
                  "nested": {
                      "foo": "Foo1",
                      "nested": {
                          "bar": "Bar1",
                          "recursiveMember": {
                              "foo": "Foo2",
                              "nested": {
                                  "bar": "Bar2"
                              }
                          }
                      }
                  }
              }""",
        bodyMediaType: "application/json",
        headers: {
            "Content-Type": "application/json"
        },
        params: {
            nested: {
                foo: "Foo1",
                nested: {
                    bar: "Bar1",
                    recursiveMember: {
                        foo: "Foo2",
                        nested: {
                            bar: "Bar2"
                        }
                    }
                }
            }
        }
    }
])

apply RecursiveShapes @httpResponseTests([
    {
        id: "RestJsonRecursiveShapes",
        documentation: "Serializes recursive structures",
        protocol: restJson1,
        code: 200,
        body: """
              {
                  "nested": {
                      "foo": "Foo1",
                      "nested": {
                          "bar": "Bar1",
                          "recursiveMember": {
                              "foo": "Foo2",
                              "nested": {
                                  "bar": "Bar2"
                              }
                          }
                      }
                  }
              }""",
        bodyMediaType: "application/json",
        headers: {
            "Content-Type": "application/json"
        },
        params: {
            nested: {
                foo: "Foo1",
                nested: {
                    bar: "Bar1",
                    recursiveMember: {
                        foo: "Foo2",
                        nested: {
                            bar: "Bar2"
                        }
                    }
                }
            }
        }
    }
])

apply InlineDocument @httpRequestTests([
    {
        id: "InlineDocumentInput",
        documentation: "Serializes inline documents as part of the JSON request payload with no escaping.",
        protocol: restJson1,
        method: "PUT",
        uri: "/InlineDocument",
        body: """
              {
                  "stringValue": "string",
                  "documentValue": {
                      "foo": "bar"
                  }
              }""",
        bodyMediaType: "application/json",
        headers: {"Content-Type": "application/json"},
        params: {
            stringValue: "string",
            documentValue: {
                foo: "bar"
            }
        }
    }
])

apply InlineDocument @httpResponseTests([
    {
        id: "InlineDocumentOutput",
        documentation: "Serializes inline documents as part of the JSON response payload with no escaping.",
        protocol: restJson1,
        code: 200,
        body: """
            {
                "stringValue": "string",
                "documentValue": {
                    "foo": "bar"
                }
            }""",
        bodyMediaType: "application/json",
        headers: {"Content-Type": "application/json"},
        params: {
            stringValue: "string",
            documentValue: {
                foo: "bar"
            }
        }
    }
])

apply InlineDocumentAsPayload @httpRequestTests([
    {
        id: "InlineDocumentAsPayloadInput",
        documentation: "Serializes an inline document as the target of the httpPayload trait.",
        protocol: restJson1,
        method: "PUT",
        uri: "/InlineDocumentAsPayload",
        body: """
              {
                  "foo": "bar"
              }""",
        bodyMediaType: "application/json",
        headers: {"Content-Type": "application/json"},
        params: {
            documentValue: {
                foo: "bar"
            }
        }
    }
])

apply InlineDocumentAsPayload @httpResponseTests([
    {
        id: "InlineDocumentAsPayloadInputOutput",
        documentation: "Serializes an inline document as the target of the httpPayload trait.",
        protocol: restJson1,
        code: 200,
        body: """
            {
                "foo": "bar"
            }""",
        bodyMediaType: "application/json",
        headers: {"Content-Type": "application/json"},
        params: {
            documentValue: {
                foo: "bar"
            }
        }
    }
])

structure RecursiveShapesInputOutput {
    nested: RecursiveShapesInputOutputNested1
}

structure RecursiveShapesInputOutputNested1 {
    foo: String,
    nested: RecursiveShapesInputOutputNested2
}

structure RecursiveShapesInputOutputNested2 {
    bar: String,
    recursiveMember: RecursiveShapesInputOutputNested1,
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

structure Nested {
    member1: String,
    member2: String
}

apply SmokeTest @httpResponseTests([
    {
        id: "SmokeTest",
        documentation: "DeSerializes a smoke test request with body, headers, query params, and prefixHeaders",
        protocol: restJson1,
        code: 200,
        headers: {
            "X-String": "Hello",
            "X-Int": "1",
            "X-Bool": "false"
        },
        body: """
        {
          "payload1": "explicit string",
          "payload2": 1,
          "payload3": {
            "member1": "test string",
            "member2": "test string 2"
          }
        }
        """,
        bodyMediaType: "application/json",
        params: {
            strHeader: "Hello",
            intHeader: 1,
            boolHeader: false,
            payload1: "explicit string",
            payload2: 1,
            payload3: {
              member1: "test string",
              member2: "test string 2"
            }
        }
    }
])

structure SmokeTestResponse {
        @httpHeader("X-String")
        strHeader: String,

        @httpHeader("X-Int")
        intHeader: Integer,

        @httpHeader("X-Bool")
        boolHeader: Boolean,

        payload1: String,
        payload2: Integer,
        payload3: Nested
}

@error("client")
structure SmokeTestError {}


@http(method: "POST", uri: "/explicit/string")
operation ExplicitString {
    input: ExplicitStringRequest,
    output: ExplicitStringResponse
}

structure ExplicitStringRequest {
    @httpPayload
    payload1: String
}

structure ExplicitStringResponse {
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
    input: ExplicitBlobRequest,
    output: ExplicitBlobResponse
}

structure ExplicitBlobRequest {
    @httpPayload
    payload1: Blob
}

structure ExplicitBlobResponse {
    @httpPayload
    payload1: Blob
}

@streaming
blob BodyStream

@http(method: "POST", uri: "/explicit/blobstream")
operation ExplicitBlobStream {
    input: ExplicitBlobStreamRequest,
    output: ExplicitBlobStreamResponse
}

structure ExplicitBlobStreamRequest {
    @httpPayload
    payload1: BodyStream
}

structure ExplicitBlobStreamResponse {
    @httpPayload
    payload1: BodyStream
}

@http(method: "POST", uri: "/explicit/struct")
operation ExplicitStruct {
    input: ExplicitStructRequest,
    output: ExplicitStructResponse
}

structure Nested4 {
    member1: Integer,
    // sanity check, member serialization for non top-level (bound to the operation input) aggregate shapes
    intList: IntList,
    intMap: IntMap,
    stringMap: NestedStringMap
}

map NestedStringMap {
   key: String,
   value: StringList
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

structure ExplicitStructResponse {
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

list NestedLongList {
    member: LongList
}

list LongList {
    member: Long
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
    input: ListInputRequest,
    output: ListOutputResponse
}

structure ListInputRequest {
    enumList: EnumList,
    intList: IntList,
    structList: StructList,
    nestedIntList: NestedIntList,
    blobList: BlobList
}

structure ListOutputResponse {
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

map NestedMap {
    key: String,
    value: IntMap
}

@http(method: "POST", uri: "/input/map")
operation MapInput {
    input: MapInputRequest,
    output: MapOutputResponse
}

structure MapInputRequest {
    intMap: IntMap,
    structMap: StructMap,
    enumMap: EnumMap,
    blobMap: BlobMap,
    dateMap: DateMap
}

structure MapOutputResponse {
    intMap: IntMap,
    structMap: StructMap,
    enumMap: EnumMap,
    blobMap: BlobMap,
    nestedMap: NestedMap,
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
    input: TimestampInputRequest,
    output: TimestampOutputResponse
}

list NestedTimestampList {
    member: TimestampList
}

list TimestampList {
    @timestampFormat("date-time")
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

    @required
    inheritedTimestamp: CommonTimestamp,

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

structure TimestampOutputResponse {
    // (protocol default)
    normal: Timestamp,

    @timestampFormat("date-time")
    dateTime: Timestamp,

    @timestampFormat("epoch-seconds")
    epochSeconds: Timestamp,

    @timestampFormat("http-date")
    httpDate: Timestamp,

    @required
    inheritedTimestamp: CommonTimestamp,

    nestedTimestampList: NestedTimestampList,

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
@externalDocumentation("httpPrefixHeaders Trait": "https://smithy.io/2.0/spec/http-bindings.html#httpprefixheaders-trait")
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

apply HttpPrefixHeaders @httpResponseTests([
    {
        id: "RestJsonHttpPrefixHeadersAreNotPresent",
        documentation: "No prefix headers are DeSerialized because the value is empty",
        protocol: restJson1,
        code: 200,
        body: "",
        headers: {
            "X-Foo": "Foo"
        },
        params: {
            foo: "Foo"
        }
    },
    {
        id: "RestJsonHttpPrefixHeadersPresent",
        documentation: "Deserialize prefix headers",
        protocol: restJson1,
        code: 200,
        body: "",
        headers: {
            "X-Foo": "Foo",
            "X-Foo-abc": "ABC",
            "X-Foo-xyz": "XYZ"
        },
        params: {
            foo: "Foo",
            fooMap: {
                abc: "ABC",
                xyz: "XYZ"
            }
        }
    }
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

/// This operation uses unions for inputs and outputs.
@idempotent
@http(uri: "/JsonUnions", method: "PUT")
operation JsonUnions {
    input: UnionInputOutput,
    output: UnionInputOutput,
}

@http(uri: "/IndirectEnumOperation", method: "POST")
operation IndirectEnumOperation {
    input: IndirectEnumInputOutput
    output: IndirectEnumInputOutput
}

@timestampFormat("http-date")
timestamp CommonTimestamp

/// A shared structure that contains a single union member.
structure UnionInputOutput {
    contents: MyUnion
}

/// A union with a representative set of types for members.
union MyUnion {
    stringValue: String,
    booleanValue: Boolean,
    numberValue: Integer,
    blobValue: Blob,
    timestampValue: Timestamp,
    inheritedTimestamp: CommonTimestamp,
    enumValue: FooEnum,
    listValue: StringList,
    mapValue: StringMap,
    structureValue: GreetingWithErrorsOutput,
}

list StringList {
    member: String,
}

@enum([
    {
        name: "FOO",
        value: "Foo",
    },
    {
        name: "BAZ",
        value: "Baz",
    },
    {
        name: "BAR",
        value: "Bar",
    },
    {
        name: "ONE",
        value: "1",
    },
    {
        name: "ZERO",
        value: "0",
    },
])
string FooEnum

apply JsonUnions @httpRequestTests([
    {
        id: "RestJsonSerializeStringUnionValue",
        documentation: "Serializes a string union value",
        protocol: restJson1,
        method: "PUT",
        "uri": "/JsonUnions",
        body: """
            {
                "contents": {
                    "stringValue": "foo"
                }
            }""",
        bodyMediaType: "application/json",
        headers: {"Content-Type": "application/json"},
        params: {
            contents: {
                stringValue: "foo"
            }
        }
    }
])

apply JsonUnions @httpResponseTests([
    {
        id: "RestJsonDeserializeStringUnionValue",
        documentation: "Deserializes a string union value",
        protocol: restJson1,
        code: 200,
        body: """
            {
                "contents": {
                    "stringValue": "foo"
                }
            }""",
        bodyMediaType: "application/json",
        headers: {"Content-Type": "application/json"},
        params: {
            contents: {
                stringValue: "foo"
            }
        }
    }
])

@http(uri: "/GreetingWithErrors", method: "PUT")
operation GreetingWithErrors {
    output: GreetingWithErrorsOutput,
    errors: [InvalidGreeting, ComplexError, FooError]
}

structure GreetingWithErrorsOutput {
    @httpHeader("X-Greeting")
    greeting: String,
}

/// This error is thrown when an invalid greeting value is provided.
@error("client")
@httpError(400)
structure InvalidGreeting {
    Message: String,
}

/// This error is thrown when a request is invalid.
@error("client")
@httpError(403)
structure ComplexError {
    // Errors support HTTP bindings!
    @httpHeader("X-Header")
    Header: String,

    TopLevel: String,

    Nested: ComplexNestedErrorData,
}

structure ComplexNestedErrorData {
    @jsonName("Fooooo")
    Foo: String,
}

/// This error has test cases that test some of the dark corners of Amazon service
/// framework history. It should only be implemented by clients.
@error("server")
@httpError(500)
@tags(["client-only"])
structure FooError {}

apply ComplexError @httpResponseTests([
    {
        id: "RestJsonComplexErrorWithNoMessage",
        documentation: "Serializes a complex error with no message member",
        protocol: restJson1,
        params: {
            Header: "Header",
            TopLevel: "Top level",
            Nested: {
                Foo: "bar"
            }
        },
        code: 403,
        headers: {
            "Content-Type": "application/json",
            "X-Header": "Header",
            "X-Amzn-Errortype": "ComplexError",
        },
        body: """
              {
                  "TopLevel": "Top level",
                  "Nested": {
                      "Fooooo": "bar"
                  }
              }""",
        bodyMediaType: "application/json",
    }
])

apply FooError @httpResponseTests([
    {
        id: "RestJsonFooErrorUsingXAmznErrorType",
        documentation: "Serializes the X-Amzn-ErrorType header. For an example service, see Amazon EKS.",
        protocol: restJson1,
        code: 500,
        headers: {
            "X-Amzn-Errortype": "FooError",
        },
    }
])

structure JsonListsInputOutput {
    stringList: StringList,
    sparseStringList: SparseStringList,
    booleanList: BooleanList,
    stringSet: StringSet,
    integerList: IntegerList,
    timestampList: TimestampList,
    nestedStringList: NestedStringList
}

list NestedStringList {
    member: StringList
}

list BooleanList {
    member: Boolean
}

set StringSet {
    member: String
}

list IntegerList {
    member: Integer
}

@sparse
list SparseStringList {
    member: String
}

@idempotent
@http(uri: "/HttpResponseCode", method: "PUT")
operation HttpResponseCode {
    output: HttpResponseCodeOutput
}

structure HttpResponseCodeOutput {
    @httpResponseCode
    Status: Integer
}


structure JsonMapsInputOutput {
    denseStructMap: DenseStructMap,
    sparseStructMap: SparseStructMap,
    denseNumberMap: DenseNumberMap,
    denseBooleanMap: DenseBooleanMap,
    denseStringMap: DenseStringMap,
    sparseNumberMap: SparseNumberMap,
    sparseBooleanMap: SparseBooleanMap,
    sparseStringMap: SparseStringMap,
}

structure GreetingStruct {
    hi: String
}

map DenseStructMap {
    key: String,
    value: GreetingStruct
}

@sparse
map SparseStructMap {
    key: String,
    value: GreetingStruct
}

map DenseBooleanMap {
    key: String,
    value: Boolean
}

map DenseNumberMap {
    key: String,
    value: Integer
}

map DenseStringMap {
    key: String,
    value: String
}

@sparse
map SparseStringMap {
    key: String,
    value: String
}

@sparse
map SparseBooleanMap {
    key: String,
    value: Boolean
}

@sparse
map SparseNumberMap {
    key: String,
    value: Integer
}


structure PrimitiveTypesStruct {
    str: String,
    intVal: Integer,
    primitiveIntVal: PrimitiveInteger,
    shortVal: Short,
    primitiveShortVal: PrimitiveShort,
    longVal: Long,
    primitiveLongVal: PrimitiveLong,
    booleanVal: Boolean,
    primitiveBooleanVal: PrimitiveBoolean,
    floatVal: Float,
    primitiveFloatVal: PrimitiveFloat,
    doubleVal: Double,
    primitiveDoubleVal: PrimitiveDouble,
    byteVal: Byte,
    primitiveByteVal: PrimitiveByte
}

structure QueryIdempotencyTokenAutoFillInput {
    @httpQuery("token")
    @idempotencyToken
    token: String,
}

structure IdempotencyTokenWithHttpHeaderInput {
    @httpHeader("token")
    @idempotencyToken
    header: String,
}

structure IdempotencyTokenWithHttpPayloadTraitOnTokenInput {
    @httpPayload
    @idempotencyToken
    bodyIsToken: String,
}

structure IdempotencyTokenWithoutHttpPayloadTraitOnAnyMemberInput {
    stringValue: String,
    documentValue: Document,

    @idempotencyToken
    token: String,
}

structure IdempotencyTokenWithoutHttpPayloadTraitOnTokenInput {
    @httpPayload
    body: String,

    @httpHeader("token")
    @idempotencyToken
    token: String,
}

union IndirectEnum {
    some: IndirectEnum
    other: String
}

structure IndirectEnumInputOutput {
    value: IndirectEnum
}

@http(method: "POST", uri: "/RequiredHttpFields/{label1}/{label2}")
operation RequiredHttpFields {
    input: RequiredHttpFieldsInput
}

structure RequiredHttpFieldsInput {
    @httpLabel
    @required
    label1: String,

    @httpLabel
    @required
    label2: String,

    @httpPayload
    payload: String,

    @httpQuery("Query1")
    @required
    query1: String

    @httpQuery("Query2")
    @required
    query2: TimestampList,

    @httpQuery("Query3")
    @required
    @length(min: 1)
    query3: String
}

@http(method: "POST", uri: "/messages/{room}")
operation PublishMessagesInitialRequest {
    input: PublishMessagesInputInitialRequest
}

@input
structure PublishMessagesInputInitialRequest {
    @httpLabel
    @required
    room: String

    @httpPayload
    messages: MessageStream
}


@http(method: "POST", uri: "/messages")
operation PublishMessagesNoInitialRequest {
    input: PublishMessagesInputNoInitialRequest
}

@input
structure PublishMessagesInputNoInitialRequest {
    @httpPayload
    messages: MessageStream
}

@streaming
union MessageStream {
    message: Message
}

structure Message {
    message: String
}
