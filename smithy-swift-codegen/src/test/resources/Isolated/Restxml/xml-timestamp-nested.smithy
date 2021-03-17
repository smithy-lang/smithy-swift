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
        XmlTimestampsNested,
        XmlTimestampsNestedHTTPDate
    ]
}

@http(uri: "/XmlTimestampsNested", method: "POST")
operation XmlTimestampsNested {
    input: XmlTimestampsNestedInputOutput,
    output: XmlTimestampsNestedInputOutput
}

structure XmlTimestampsNestedInputOutput {
    nestedTimestampList: NestedNestedTimestampList
}

list NestedNestedTimestampList {
    member: NestedTimestampList
}

list NestedTimestampList {
    @timestampFormat("epoch-seconds")
    member: Timestamp
}




@http(uri: "/XmlTimestampsNestedHTTPDate", method: "POST")
operation XmlTimestampsNestedHTTPDate {
    input: XmlTimestampsNestedHTTPDateInputOutput,
    output: XmlTimestampsNestedHTTPDateInputOutput
}

structure XmlTimestampsNestedHTTPDateInputOutput {
    nestedTimestampList: NestedNestedHTTPDateTimestampList
}

list NestedNestedHTTPDateTimestampList {
    member: NestedHTTPDateTimestampList
}

list NestedHTTPDateTimestampList {
    @timestampFormat("http-date")
    member: Timestamp
}
