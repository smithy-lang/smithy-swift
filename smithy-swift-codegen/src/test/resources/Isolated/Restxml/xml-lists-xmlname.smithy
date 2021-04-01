$version: "1.0"

namespace aws.protocoltests.restxml

use aws.api#service
use aws.protocols#restXml
use smithy.test#httpRequestTests
use smithy.test#httpResponseTests

@service(sdkId: "Rest Xml List")
@restXml
service RestXml {
    version: "2019-12-16",
    operations: [
        XmlListXmlName
    ]
}

@http(uri: "/XmlListXmlName", method: "POST")
operation XmlListXmlName {
    input: XmlListXmlNameInputOutput,
    output: XmlListXmlNameInputOutput
}

structure XmlListXmlNameInputOutput {
    @xmlName("renamed")
    renamedListMembers: RenamedListMembers
}

list RenamedListMembers {
    @xmlName("item")
    member: String,
}