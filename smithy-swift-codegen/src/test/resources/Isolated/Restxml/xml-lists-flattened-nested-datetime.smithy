$version: "1.0"

namespace aws.protocoltests.restxml

use aws.api#service
use aws.protocols#restXml
use smithy.test#httpRequestTests
use smithy.test#httpResponseTests

@service(sdkId: "Rest Xml List timestamp nested flattened")
@restXml
service RestXml {
    version: "2019-12-16",
    operations: [
        XmlTimestampsNestedFlattened,
    ]
}

@http(uri: "/XmlTimestampsNestedFlattened", method: "POST")
operation XmlTimestampsNestedFlattened {
    input: XmlTimestampsNestedFlattenedInputOutput,
    output: XmlTimestampsNestedFlattenedInputOutput
}

structure XmlTimestampsNestedFlattenedInputOutput {
    @xmlFlattened
    nestedTimestampList: NestedNestedFlattenedTimestampList
}

list NestedNestedFlattenedTimestampList {
    @xmlName("nestedMember")
    @xmlNamespace(uri: "http://baz.com", prefix: "baz")
    member: NestedTimestampList
}

list NestedTimestampList {
    @timestampFormat("epoch-seconds")
    member: Timestamp
}


