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
        XmlTimestampsNestedXmlName
    ]
}

@http(uri: "/XmlTimestampsNestedXmlName", method: "POST")
operation XmlTimestampsNestedXmlName {
    input: XmlTimestampsNestedXmlNameInputOutput,
    output: XmlTimestampsNestedXmlNameInputOutput
}

structure XmlTimestampsNestedXmlNameInputOutput {
    nestedTimestampList: NestedNestedTimestampList
}

list NestedNestedTimestampList {
    @xmlName("nestedTag1")
    member: NestedTimestampList
}

list NestedTimestampList {
    @xmlName("nestedTag2")
    @timestampFormat("epoch-seconds")
    member: Timestamp
}