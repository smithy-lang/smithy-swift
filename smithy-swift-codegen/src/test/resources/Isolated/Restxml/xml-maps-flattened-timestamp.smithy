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
        XmlMapsFlattenedTimestamps
    ]
}

@http(uri: "/XmlMapsTimestamps", method: "POST")
operation XmlMapsFlattenedTimestamps {
    input: XmlMapsFlattenedTimestampsInputOutput,
    output: XmlMapsFlattenedTimestampsInputOutput
}

structure XmlMapsFlattenedTimestampsInputOutput {
    @xmlFlattened
    timestampMap: TimestampMap
}

map TimestampMap {
    key: String,
    @timestampFormat("epoch-seconds")
    value: Timestamp
}
