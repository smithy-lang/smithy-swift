
$version: "1.0"

namespace aws.protocoltests.restxml

use aws.api#service
use aws.protocols#restXml
use smithy.test#httpRequestTests
use smithy.test#httpResponseTests

@service(sdkId: "Rest Xml namespace on servicerestxml")
@xmlNamespace(uri: "https://example.com")
@restXml
service RestXml {
    version: "2019-12-16",
    operations: [
        XmlNamespacesOnService
    ]
}

@http(uri: "/XmlNamespacesOnService", method: "POST")
operation XmlNamespacesOnService {
    input: XmlNamespacesOnServiceInputOutput,
    output: XmlNamespacesOnServiceInputOutput
}

structure XmlNamespacesOnServiceInputOutput {
    foo: String,

    @xmlNamespace(prefix: "xsi", uri: "https://example.com")
    nested: NestedWithNamespace,
}

structure NestedWithNamespace {
    @xmlAttribute
    @xmlName("xsi:someName")
    attrField: String,
}