$version: "1.0"

namespace aws.protocoltests.restxml

use aws.api#service
use aws.protocols#restXml
use smithy.test#httpRequestTests
use smithy.test#httpResponseTests

@service(sdkId: "Rest Xml maps Flattened namespace")
@restXml
service RestXml {
    version: "2019-12-16",
    operations: [
        XmlMapsFlattenedXmlNamespace
    ]
}

@http(uri: "/XmlMapsFlattenedXmlNamespace", method: "POST")
operation XmlMapsFlattenedXmlNamespace {
    input: XmlMapsFlattenedXmlNamespaceInputOutput,
    output: XmlMapsFlattenedXmlNamespaceInputOutput
}

@xmlNamespace(uri: "http://aoo.com")
structure XmlMapsFlattenedXmlNamespaceInputOutput {
    @xmlNamespace(uri: "http://boo.com")
    @xmlFlattened
    myMap: XmlMapsXmlNamespaceInputOutputMap,
}

@xmlNamespace(uri: "http://coo.com")
map XmlMapsXmlNamespaceInputOutputMap {
    @xmlName("Uid")
    @xmlNamespace(uri: "http://doo.com")
    key: String,

    @xmlNamespace(uri: "http://eoo.com")
    @xmlName("Val")
    value: String
}