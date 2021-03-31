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
        XmlNestedNestedWrappedList
    ]
}

@http(uri: "/XmlNestedNestedWrappedList", method: "POST")
operation XmlNestedNestedWrappedList {
    input: XmlNestedNestedWrappedListInputOutput,
    output: XmlNestedNestedWrappedListInputOutput
}

structure XmlNestedNestedWrappedListInputOutput {
    nestedNestedStringList: NestedNestedStringList
}

list NestedNestedStringList {
    member: NestedStringList
}

list NestedStringList {
    member: StringList
}

list StringList {
    member: String
}