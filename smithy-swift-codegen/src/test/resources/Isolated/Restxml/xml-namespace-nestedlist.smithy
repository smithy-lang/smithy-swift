
$version: "1.0"

namespace aws.protocoltests.restxml

use aws.api#service
use aws.protocols#restXml
use smithy.test#httpRequestTests
use smithy.test#httpResponseTests

@service(sdkId: "Rest Xml namespace")
@restXml
service RestXml {
    version: "2019-12-16",
    operations: [
        XmlNamespaceNestedList
    ]
}

@http(uri: "/XmlNamespaceNestedList", method: "POST")
operation XmlNamespaceNestedList {
    input: XmlNamespaceNestedListInputOutput,
    output: XmlNamespaceNestedListInputOutput
}

@xmlNamespace(uri: "http://foo.com")
structure XmlNamespaceNestedListInputOutput {
    @xmlNamespace(uri: "http://aux.com")
    nested: XmlNamespacedList
}

list XmlNamespacedList {
    @xmlNamespace(uri: "http://bux.com", prefix: "baz")
    member: XmlNestedNamespacedList,
}

list XmlNestedNamespacedList {
    @xmlNamespace(uri: "http://bar.com", prefix: "bzzzz")
    member: String,
}