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
        XmlMapsTwo
    ]
}

@http(uri: "/XmlMapsTwo", method: "POST")
operation XmlMapsTwo {
    input: XmlMapsTwoInputOutput,
    output: XmlMapsTwoInputOutput
}

structure XmlMapsTwoInputOutput {
    myMap: XmlMapsInputOutputMap,
    mySecondMap: XmlMapsInputOutputMap,
}

map XmlMapsInputOutputMap {
    key: String,
    value: String
}
