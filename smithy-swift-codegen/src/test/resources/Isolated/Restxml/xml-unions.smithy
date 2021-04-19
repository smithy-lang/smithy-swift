$version: "1.0"

namespace aws.protocoltests.restxml

use aws.api#service
use aws.protocols#restXml
use smithy.test#httpRequestTests
use smithy.test#httpResponseTests

@service(sdkId: "Rest Xml unions")
@restXml
service RestXml {
    version: "2019-12-16",
    operations: [
        XmlUnions
    ]
}

@idempotent
@http(uri: "/XmlUnions", method: "PUT")
operation XmlUnions {
    input: XmlUnionsInputOutput,
    output: XmlUnionsInputOutput
}

structure XmlUnionsInputOutput {
    unionValue: XmlUnionShape,
}

union XmlUnionShape {
    doubleValue: Double,

    unionValue: XmlUnionShape,
    structValue: XmlNestedUnionStruct,
}

structure XmlNestedUnionStruct {
    stringValue: String,
    doubleValue: Double,
}