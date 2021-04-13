$version: "1.0"

namespace aws.protocoltests.restxml

use aws.api#service
use aws.protocols#restXml
use smithy.test#httpRequestTests
use smithy.test#httpResponseTests

@service(sdkId: "Rest Xml flattened nested maps xmlName")
@restXml
service RestXml {
    version: "2019-12-16",
    operations: [
        XmlMapsFlattenedNestedXmlName
    ]
}

@http(uri: "/XmlMapsFlattenedNestedXmlName", method: "POST")
operation XmlMapsFlattenedNestedXmlName {
    input: XmlMapsFlattenedNestedXmlNameInputOutput,
    output: XmlMapsFlattenedNestedXmlNameInputOutput
}

structure XmlMapsFlattenedNestedXmlNameInputOutput {
    @xmlFlattened
    myMap: XmlMapsNestedXmlNameInputOutputMap,
}

map XmlMapsNestedXmlNameInputOutputMap {
    @xmlName("yek")
    key: String,

    @xmlName("eulav")
    value: XmlMapsNestedNestedInputOutputMap
}

map XmlMapsNestedNestedInputOutputMap {
    @xmlName("K")
    key: String,

    @xmlName("V")
    value: String
}