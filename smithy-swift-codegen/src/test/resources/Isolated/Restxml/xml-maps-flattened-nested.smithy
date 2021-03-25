$version: "1.0"

namespace aws.protocoltests.restxml

use aws.api#service
use aws.protocols#restXml
use smithy.test#httpRequestTests
use smithy.test#httpResponseTests

@service(sdkId: "Rest Xml flattened nested maps")
@restXml
service RestXml {
    version: "2019-12-16",
    operations: [
        XmlMapsFlattenedNested
    ]
}

@http(uri: "/XmlMapsFlattenedNested", method: "POST")
operation XmlMapsFlattenedNested {
    input: XmlMapsFlattenedNestedInputOutput,
    output: XmlMapsFlattenedNestedInputOutput
}

structure XmlMapsFlattenedNestedInputOutput {
    @xmlFlattened
    myMap: XmlMapsNestedInputOutputMap,
}

map XmlMapsNestedInputOutputMap {
    key: String,
    value: XmlMapsNestedNestedInputOutputMap
}

map XmlMapsNestedNestedInputOutputMap {
    key: String,
    value: GreetingStruct
}

structure GreetingStruct {
    hi: String,
}