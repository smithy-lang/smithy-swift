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
        XmlNestedWrappedList
    ]
}

@http(uri: "/XmlNestedWrappedList", method: "POST")
operation XmlNestedWrappedList {
    input: XmlNestedWrappedListInputOutput,
    output: XmlNestedWrappedListInputOutput
}

structure XmlNestedWrappedListInputOutput {
    nestedStringList: NestedStringList
}

 list NestedStringList {
     member: StringList
 }

 list StringList {
     member: String
 }