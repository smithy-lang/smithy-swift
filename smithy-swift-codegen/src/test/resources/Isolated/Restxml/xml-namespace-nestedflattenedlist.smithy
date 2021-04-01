
$version: "1.0"

namespace aws.protocoltests.restxml

use aws.api#service
use aws.protocols#restXml
use smithy.test#httpRequestTests
use smithy.test#httpResponseTests

@service(sdkId: "Rest Xml namespace nested flat")
@restXml
service RestXml {
    version: "2019-12-16",
    operations: [
        XmlNamespaceNestedFlattenedList
    ]
}

@http(uri: "/XmlNamespaceNestedFlattenedList", method: "POST")
operation XmlNamespaceNestedFlattenedList {
    input: XmlNamespaceNestedFlattenedListInputOutput,
    output: XmlNamespaceNestedFlattenedListInputOutput
}

@xmlNamespace(uri: "http://foo.com")
structure XmlNamespaceNestedFlattenedListInputOutput {
    @xmlNamespace(uri: "http://aux.com")
    @xmlFlattened
    nested: XmlNamespacedList
}

list XmlNamespacedList {
    @xmlNamespace(uri: "http://bux.com", prefix: "baz")
    @xmlName("containingItem")
    member: XmlNestedNamespacedList,
}

list XmlNestedNamespacedList {
    @xmlNamespace(uri: "http://bar.com", prefix: "bzzzz")
    @xmlName("item")
    member: String,
}