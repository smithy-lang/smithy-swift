$version: "1.0"

namespace aws.protocoltests.restxml

use aws.api#service
use aws.protocols#restXml
use smithy.test#httpRequestTests
use smithy.test#httpResponseTests

@service(sdkId: "Rest Xml Attributes")
@restXml
service RestXml {
    version: "2019-12-16",
    operations: [
        XmlAttributes
    ]
}

@idempotent
@http(uri: "/XmlAttributes", method: "PUT")
operation XmlAttributes {
    input: XmlAttributesInputOutput,
    output: XmlAttributesInputOutput
}


structure XmlAttributesInputOutput {
    foo: String,

    @xmlAttribute
    @xmlName("test")
    attr: String,
}