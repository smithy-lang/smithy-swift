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
        XmlMapsNestedNested
    ]
}

@http(uri: "/XmlMapsNestedNested", method: "POST")
operation XmlMapsNestedNested {
    input: XmlMapsNestedInputOutput,
    output: XmlMapsNestedInputOutput
}

structure XmlMapsNestedInputOutput {
    myMap: XmlMapsNestedInputOutputMap,
}

map XmlMapsNestedInputOutputMap {
    key: String,
    value: XmlMapsNestedNestedInputOutputMap
}

map XmlMapsNestedNestedInputOutputMap {
    key: String,
    value: XmlMapsNestedNestedNestedInputOutputMap
}

map XmlMapsNestedNestedNestedInputOutputMap {
    key: String,
    value: GreetingStruct
}
structure GreetingStruct {
    hi: String,
}