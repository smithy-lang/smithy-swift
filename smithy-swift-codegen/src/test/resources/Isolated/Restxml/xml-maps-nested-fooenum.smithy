$version: "1.0"

namespace aws.protocoltests.restxml

use aws.api#service
use aws.protocols#restXml
use smithy.test#httpRequestTests
use smithy.test#httpResponseTests

@service(sdkId: "Rest Xml maps")
@restXml
service RestXml {
    version: "2019-12-16",
    operations: [
        NestedXmlMaps
    ]
}

@http(uri: "/NestedXmlMaps", method: "POST")
operation NestedXmlMaps {
    input: NestedXmlMapsInputOutput,
    output: NestedXmlMapsInputOutput,
}

structure NestedXmlMapsInputOutput {
    nestedMap: NestedMap,

    @xmlFlattened
    flatNestedMap: NestedMap,
}

map NestedMap {
    key: String,
    value: FooEnumMap,
}

map FooEnumMap {
    key: String,
    value: FooEnum,
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