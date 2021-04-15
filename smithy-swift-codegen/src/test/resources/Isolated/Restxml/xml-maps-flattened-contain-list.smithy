$version: "1.0"

namespace aws.protocoltests.restxml

use aws.api#service
use aws.protocols#restXml
use smithy.test#httpRequestTests
use smithy.test#httpResponseTests

@service(sdkId: "Rest Xml maps contain list")
@restXml
service RestXml {
    version: "2019-12-16",
    operations: [
        XmlMapsFlattenedContainList
    ]
}

@http(uri: "/XmlMapsFlattenedContainList", method: "POST")
operation XmlMapsFlattenedContainList {
    input: XmlMapsFlattenedContainListInputOutput,
    output: XmlMapsFlattenedContainListInputOutput
}

structure XmlMapsFlattenedContainListInputOutput {
    @xmlFlattened
    myMap: XmlMapsFlattenedNestedInputOutputMap,
}

map XmlMapsFlattenedNestedInputOutputMap {
    key: String,
    value: XmlSimpleStringList
}

list XmlSimpleStringList {
    member: String
}
