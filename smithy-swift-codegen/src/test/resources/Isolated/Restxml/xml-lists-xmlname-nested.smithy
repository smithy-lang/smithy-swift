$version: "1.0"

namespace aws.protocoltests.restxml

use aws.api#service
use aws.protocols#restXml
use smithy.test#httpRequestTests
use smithy.test#httpResponseTests

@service(sdkId: "Rest Xml List xmlname nested")
@restXml
service RestXml {
    version: "2019-12-16",
    operations: [
        XmlListXmlNameNested
    ]
}

@http(uri: "/XmlListXmlNameNested", method: "POST")
operation XmlListXmlNameNested {
    input: XmlListXmlNameNestedInputOutput,
    output: XmlListXmlNameNestedInputOutput
}

structure XmlListXmlNameNestedInputOutput {
    @xmlName("renamed")
    renamedListMembers: ContainingRenamedListMembers
}

list ContainingRenamedListMembers {
    @xmlName("item")
    member: RenamedListMembers,
}

list RenamedListMembers {
    @xmlName("subItem")
    member: String
}

