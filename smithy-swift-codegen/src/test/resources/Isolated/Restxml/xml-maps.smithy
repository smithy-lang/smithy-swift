$version: "1.0"

namespace aws.protocoltests.restxml

use aws.api#service
use aws.protocols#restXml
use smithy.test#httpRequestTests
use smithy.test#httpResponseTests

@service(sdkId: "Rest Xml maps")
@restXml
service RestXml {
    version: "2019-12-16",
    operations: [
        XmlMaps,
        XmlMapsWithNameProtocol

    ]
}

@http(uri: "/XmlMaps", method: "POST")
operation XmlMaps {
    input: XmlMapsInputOutput,
    output: XmlMapsInputOutput
}

structure XmlMapsInputOutput {
    myMap: XmlMapsInputOutputMap,
}

map XmlMapsInputOutputMap {
    key: String,
    value: GreetingStruct
}

structure GreetingStruct {
    hi: String,
}

@http(uri: "/XmlMapsWithNameProtocol", method: "POST")
operation XmlMapsWithNameProtocol {
    input: XmlMapsWithNameProtocolInputOutput,
    output: XmlMapsWithNameProtocolInputOutput
}

structure XmlMapsWithNameProtocolInputOutput {
    protocol: XmlMapsInputOutputMap,
}
