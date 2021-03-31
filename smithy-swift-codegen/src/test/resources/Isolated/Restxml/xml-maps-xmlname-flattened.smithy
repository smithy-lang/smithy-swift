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
        XmlMapsXmlNameFlattened
    ]
}

@http(uri: "/XmlMapsXmlNameFlattened", method: "POST")
operation XmlMapsXmlNameFlattened {
    input: XmlMapsXmlNameFlattenedInputOutput,
    output: XmlMapsXmlNameFlattenedInputOutput
}

structure XmlMapsXmlNameFlattenedInputOutput {
    @xmlFlattened
    myMap: XmlMapsXmlNameInputOutputMap,
}

map XmlMapsXmlNameInputOutputMap {
    @xmlName("SomeCustomKey")
    key: String,

    @xmlName("SomeCustomValue")
    value: GreetingStruct
}

structure GreetingStruct {
    hi: String,
}
