$version: "1.0"

namespace aws.protocoltests.restxml

use aws.api#service
use aws.protocols#restXml
use smithy.test#httpRequestTests
use smithy.test#httpResponseTests

@service(sdkId: "Rest Xml List nested flattened xmlname")
@restXml
service RestXml {
    version: "2019-12-16",
    operations: [
        XmlListNestedFlattenedXmlName,
    ]
}

@http(uri: "/XmlListNestedFlattenedXmlName", method: "POST")
operation XmlListNestedFlattenedXmlName {
    input: XmlListNestedFlattenedXmlNameInputOutput,
    output: XmlListNestedFlattenedXmlNameInputOutput
}

structure XmlListNestedFlattenedXmlNameInputOutput {
    @xmlFlattened
    @xmlName("listOfNestedStrings")
    nestedList: NestedNestedFlattenedStringMember
}

list NestedNestedFlattenedStringMember {
    @xmlName("nestedMember")
    member: NestedStringMember
}

list NestedStringMember {
    @xmlName("nestedNestedMember")
    member: String
}


