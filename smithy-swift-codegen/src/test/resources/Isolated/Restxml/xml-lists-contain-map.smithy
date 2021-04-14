$version: "1.0"

namespace aws.protocoltests.restxml

use aws.api#service
use aws.protocols#restXml
use smithy.test#httpRequestTests
use smithy.test#httpResponseTests

@service(sdkId: "Rest Xml list contain map")
@restXml
service RestXml {
    version: "2019-12-16",
    operations: [
        XmlListContainMap,
    ]
}

@http(uri: "/XmlListContainMap", method: "POST")
operation XmlListContainMap {
    input: XmlListContainMapInputOutput,
    output: XmlListContainMapInputOutput
}

structure XmlListContainMapInputOutput {
    myList: XmlListContainMapsInputOutputList,
}

list XmlListContainMapsInputOutputList {
    member: MySimpleMap
}

map MySimpleMap {
    key: String,
    value: String
}