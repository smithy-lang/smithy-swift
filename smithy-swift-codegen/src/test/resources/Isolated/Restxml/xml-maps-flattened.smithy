$version: "1.0"

namespace aws.protocoltests.restxml

use aws.api#service
use aws.protocols#restXml
use smithy.test#httpRequestTests
use smithy.test#httpResponseTests

@service(sdkId: "Rest Xml flattened maps")
@restXml
service RestXml {
    version: "2019-12-16",
    operations: [
        XmlFlattenedMaps
    ]
}

@http(uri: "/XmlFlattenedMaps", method: "POST")
operation XmlFlattenedMaps {
    input: XmlFlattenedMapsInputOutput,
    output: XmlFlattenedMapsInputOutput
}

structure XmlFlattenedMapsInputOutput {
    @xmlFlattened
    myMap: XmlFlattenedMapsInputOutputMap,
}

map XmlFlattenedMapsInputOutputMap {
    key: String,
    value: GreetingStruct
}

structure GreetingStruct {
    hi: String,
}