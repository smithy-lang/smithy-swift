$version: "1.0"

namespace aws.protocoltests.restxml

use aws.api#service
use aws.protocols#restXml
use smithy.test#httpRequestTests
use smithy.test#httpResponseTests

@service(sdkId: "Rest Xml timestamp with name")
@restXml
service RestXml {
    version: "2019-12-16",
    operations: [
        XmlTimestampsXmlName
    ]
}

@http(uri: "/XmlTimestampsXmlName", method: "POST")
operation XmlTimestampsXmlName {
    input: XmlTimestampsXmlNameInputOutput,
    output: XmlTimestampsXmlNameInputOutput
}

structure XmlTimestampsXmlNameInputOutput {
    @xmlName("notNormalName")
    normal: Timestamp,

    @timestampFormat("date-time")
    dateTime: Timestamp,
}