$version: "1.0"

namespace aws.protocoltests.restxml

use aws.api#service
use aws.protocols#restXml
use smithy.test#httpRequestTests
use smithy.test#httpResponseTests

@service(sdkId: "Rest Xml maps xmlname with nested")
@restXml
service RestXml {
    version: "2019-12-16",
    operations: [
        XmlMapsXmlNameNested
    ]
}

@http(uri: "/XmlMapsXmlNameNested", method: "POST")
operation XmlMapsXmlNameNested {
    input: XmlMapsXmlNameNestedInputOutput,
    output: XmlMapsXmlNameNestedInputOutput
}

structure XmlMapsXmlNameNestedInputOutput {
    myMap: XmlMapsXmlNameNestedInputOutputMap,
}

map XmlMapsXmlNameNestedInputOutputMap {
    @xmlName("CustomKey1")
    key: String,
    @xmlName("CustomValue1")
    value: XmlMapsNestedNestedInputOutputMap
}

map XmlMapsNestedNestedInputOutputMap {
    @xmlName("CustomKey2")
    key: String,
    @xmlName("CustomValue2")
    value: GreetingStruct
}

structure GreetingStruct {
    hi: String,
}