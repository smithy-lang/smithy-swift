
$version: "1.0"

namespace aws.protocoltests.restxml

use aws.api#service
use aws.protocols#restXml
use smithy.test#httpRequestTests
use smithy.test#httpResponseTests

@service(sdkId: "Rest Xml namespace flattened list")
@restXml
service RestXml {
    version: "2019-12-16",
    operations: [
        XmlNamespaceFlattenedList
    ]
}

@http(uri: "/XmlNamespaceFlattenedList", method: "POST")
operation XmlNamespaceFlattenedList {
    input: XmlNamespaceFlattenedListInputOutput,
    output: XmlNamespaceFlattenedListInputOutput
}

@xmlNamespace(uri: "http://foo.com")
structure XmlNamespaceFlattenedListInputOutput {
    @xmlFlattened
    @xmlNamespace(uri: "http://aux.com", prefix: "baz")
    nested: XmlNamespacedList
}

list XmlNamespacedList {
    member: String,
}
