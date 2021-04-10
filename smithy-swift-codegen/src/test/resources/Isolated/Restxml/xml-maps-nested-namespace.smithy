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
        XmlMapsNestedNamespace
    ]
}

@http(uri: "/XmlMapsNestedNamespace", method: "POST")
operation XmlMapsNestedNamespace {
    input: XmlMapsNestedNamespaceInputOutput,
    output: XmlMapsNestedNamespaceInputOutput
}

@xmlNamespace(uri: "http://aoo.com")
structure XmlMapsNestedNamespaceInputOutput {
    @xmlNamespace(uri: "http://boo.com")
    myMap: XmlMapsNestedNamespaceInputOutputMap,
}

@xmlNamespace(uri: "http://coo.com")
map XmlMapsNestedNamespaceInputOutputMap {
    @xmlNamespace(uri: "http://doo.com")
    @xmlName("yek")
    key: String,

    @xmlNamespace(uri: "http://eoo.com")
    @xmlName("eulav")
    value: XmlMapsNestedNestedNamespaceInputOutputMap
}

@xmlNamespace(uri: "http://foo.com")
map XmlMapsNestedNestedNamespaceInputOutputMap {
    @xmlNamespace(uri: "http://goo.com")
    @xmlName("K")
    key: String,

    @xmlNamespace(uri: "http://hoo.com")
    @xmlName("V")
    value: String
}
