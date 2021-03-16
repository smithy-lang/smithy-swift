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
        XmlTimestamps
    ]
}

@http(uri: "/XmlTimestamps", method: "POST")
operation XmlTimestamps {
    input: XmlTimestampsNormalInputOutput,
    output: XmlTimestampsNormalInputOutput
}

structure XmlTimestampsNormalInputOutput {
    normal: Timestamp,

    @timestampFormat("date-time")
    dateTime: Timestamp,

    @timestampFormat("epoch-seconds")
    epochSeconds: Timestamp,

    @timestampFormat("http-date")
    httpDate: Timestamp,
}