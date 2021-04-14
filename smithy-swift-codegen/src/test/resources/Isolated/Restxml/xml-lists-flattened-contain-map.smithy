$version: "1.0"

namespace aws.protocoltests.restxml

use aws.api#service
use aws.protocols#restXml
use smithy.test#httpRequestTests
use smithy.test#httpResponseTests

@service(sdkId: "Rest Xml list flattened contain map")
@restXml
service RestXml {
    version: "2019-12-16",
    operations: [
        XmlListFlattenedContainMap,
    ]
}

@http(uri: "/XmlListFlattenedContainMap", method: "POST")
operation XmlListFlattenedContainMap {
    input: XmlListFlattenedContainMapInputOutput,
    output: XmlListFlattenedContainMapInputOutput
}

structure XmlListFlattenedContainMapInputOutput {
    @xmlFlattened
    myList: XmlListFlattenedContainMapsInputOutputList,
}

list XmlListFlattenedContainMapsInputOutputList {
    member: MySimpleMap
}

map MySimpleMap {
    key: String,
    value: String
}