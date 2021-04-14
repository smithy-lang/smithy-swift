$version: "1.0"

namespace aws.protocoltests.restxml

use aws.api#service
use aws.protocols#restXml
use smithy.test#httpRequestTests
use smithy.test#httpResponseTests

@service(sdkId: "Rest Xml maps namespace")
@restXml
service RestXml {
    version: "2019-12-16",
    operations: [
        XmlMapsXmlNamespace
    ]
}

@http(uri: "/XmlMapsXmlNamespace", method: "POST")
operation XmlMapsXmlNamespace {
    input: XmlMapsXmlNamespaceInputOutput,
    output: XmlMapsXmlNamespaceInputOutput
}

@xmlNamespace(uri: "http://aoo.com")
structure XmlMapsXmlNamespaceInputOutput {
    @xmlNamespace(uri: "http://boo.com")
    myMap: XmlMapsXmlNamespaceInputOutputMap,
}

@xmlNamespace(uri: "http://coo.com")
map XmlMapsXmlNamespaceInputOutputMap {
    @xmlName("Quality")
    @xmlNamespace(uri: "http://doo.com")
    key: String,

    @xmlNamespace(uri: "http://eoo.com")
    @xmlName("Degree")
    value: String
}