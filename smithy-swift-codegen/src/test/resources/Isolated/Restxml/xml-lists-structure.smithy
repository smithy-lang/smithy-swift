
$version: "1.0"

namespace aws.protocoltests.restxml

use aws.api#service
use aws.protocols#restXml
use smithy.test#httpRequestTests
use smithy.test#httpResponseTests

@service(sdkId: "Rest Xml structure list")
@restXml
service RestXml {
    version: "2019-12-16",
    operations: [
        XmlStructureLists
    ]
}

@http(uri: "/XmlStructureLists", method: "PUT")
operation XmlStructureLists {
    input: XmlListsStructureInputOutput,
    output: XmlListsStructureInputOutput,
}

structure XmlListsStructureInputOutput {
    @xmlName("myStructureList")
    structureList: StructureList
}

list StructureList {
    @xmlName("item")
    member: StructureListMember,
}

structure StructureListMember {
    @xmlName("value")
    a: String,

    @xmlName("other")
    b: String,
}