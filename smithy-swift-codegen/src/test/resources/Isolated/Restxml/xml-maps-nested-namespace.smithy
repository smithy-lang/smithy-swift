$version: "1.0"

namespace aws.protocoltests.restxml

use aws.api#service
use aws.protocols#restXml
use smithy.test#httpRequestTests
use smithy.test#httpResponseTests

@service(sdkId: "Rest Xml maps nested namespace")
@restXml
service RestXml {
    version: "2019-12-16",
    operations: [
        XmlMapsNestedXmlNamespace
    ]
}

@http(uri: "/XmlMapsNestedXmlNamespace", method: "POST")
operation XmlMapsNestedXmlNamespace {
    input: XmlMapsNestedXmlNamespaceInputOutput,
    output: XmlMapsNestedXmlNamespaceInputOutput
}

@xmlNamespace(uri: "http://aoo.com")
structure XmlMapsNestedXmlNamespaceInputOutput {
    @xmlNamespace(uri: "http://boo.com")
    myMap: XmlMapsNestedXmlNamespaceInputOutputMap,
}

@xmlNamespace(uri: "http://coo.com")
map XmlMapsNestedXmlNamespaceInputOutputMap {
    @xmlNamespace(uri: "http://doo.com")
    @xmlName("yek")
    key: String,

    @xmlNamespace(uri: "http://eoo.com")
    @xmlName("eulav")
    value: XmlMapsNestedNestedXmlNamespaceInputOutputMap
}

@xmlNamespace(uri: "http://foo.com")
map XmlMapsNestedNestedXmlNamespaceInputOutputMap {
    @xmlNamespace(uri: "http://goo.com")
    @xmlName("K")
    key: String,

    @xmlNamespace(uri: "http://hoo.com")
    @xmlName("V")
    value: String
}