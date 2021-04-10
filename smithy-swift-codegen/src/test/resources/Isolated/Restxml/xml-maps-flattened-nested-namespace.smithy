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
        XmlMapsFlattenedNestedNamespace
    ]
}

@http(uri: "/XmlMapsFlattenedNestedNamespace", method: "POST")
operation XmlMapsFlattenedNestedNamespace {
    input: XmlMapsFlattenedNestedNamespaceInputOutput,
    output: XmlMapsFlattenedNestedNamespaceInputOutput
}

@xmlNamespace(uri: "http://aoo.com")
structure XmlMapsFlattenedNestedNamespaceInputOutput {
    @xmlNamespace(uri: "http://boo.com")
    @xmlFlattened
    myMap: XmlMapsFlattenedNestedNamespaceInputOutputMap,
}

@xmlNamespace(uri: "http://coo.com")
map XmlMapsFlattenedNestedNamespaceInputOutputMap {
    @xmlNamespace(uri: "http://doo.com")
    @xmlName("yek")
    key: String,

    @xmlName("eulav")
    @xmlNamespace(uri: "http://eoo.com")
    value: XmlMapsFlattenedNestedNestedNamespaceInputOutputMap
}

@xmlNamespace(uri: "http://foo.com")
map XmlMapsFlattenedNestedNestedNamespaceInputOutputMap {
    @xmlNamespace(uri: "http://goo.com")
    @xmlName("K")
    key: String,

    @xmlNamespace(uri: "http://hoo.com")
    @xmlName("V")
    value: String
}
