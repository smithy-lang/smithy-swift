
$version: "1.0"

namespace aws.protocoltests.restxml

use aws.api#service
use aws.protocols#restXml
use smithy.test#httpRequestTests
use smithy.test#httpResponseTests

@service(sdkId: "Rest Xml Protocol")
@restXml
service RestXml {
    version: "2019-12-16",
    operations: [
        FlattenedXmlMap,
        NestedXmlMap
    ]
}

@http(uri: "/FlattenedXmlMap", method: "POST")
operation FlattenedXmlMap {
    input: FlattenedXmlMapInputOutput,
    output: FlattenedXmlMapInputOutput
}

@http(uri: "/NestedXmlMap", method: "POST")
operation NestedXmlMap {
    input: NestedXmlMapInputOutput,
    output: NestedXmlMapInputOutput
}

structure FlattenedXmlMapInputOutput {
    @xmlFlattened
    myFlattenedMap: FooEnumMap,
}

structure NestedXmlMapInputOutput {
    myNestedMap: FooEnumMap,
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


map FooEnumMap {
    key: String,
    value: FooEnum,
}