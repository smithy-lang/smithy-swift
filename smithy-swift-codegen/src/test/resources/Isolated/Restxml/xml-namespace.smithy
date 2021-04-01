
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
        XmlNamespaces
    ]
}

@http(uri: "/XmlNamespaces", method: "POST")
operation XmlNamespaces {
    input: XmlNamespacesInputOutput,
    output: XmlNamespacesInputOutput
}

@xmlNamespace(uri: "http://foo.com")
structure XmlNamespacesInputOutput {
    nested: XmlNamespaceNested
}

//This @xmlNamespace is ignored since it is a nested structure
@xmlNamespace(uri: "http://foo.com")
structure XmlNamespaceNested {
    @xmlNamespace(uri: "http://baz.com", prefix: "baz")
    foo: String,

    @xmlNamespace(uri: "http://qux.com")
    values: XmlNamespacedList
}

list XmlNamespacedList {
    @xmlNamespace(uri: "http://bux.com")
    member: String,
}