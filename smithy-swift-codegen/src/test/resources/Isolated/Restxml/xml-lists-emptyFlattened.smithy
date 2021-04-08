$version: "1.0"

namespace aws.protocoltests.restxml

use aws.api#service
use aws.protocols#restXml
use smithy.test#httpRequestTests
use smithy.test#httpResponseTests

@service(sdkId: "Rest Xml List flattened empty")
@restXml
service RestXml {
    version: "2019-12-16",
    operations: [
        XmlEmptyFlattenedLists
    ]
}

@idempotent
@http(uri: "/XmlEmptyFlattenedLists", method: "PUT")
@tags(["client-only"])
operation XmlEmptyFlattenedLists {
    input: XmlListsFlattenedInputOutput,
    output: XmlListsFlattenedInputOutput,
}

structure XmlListsFlattenedInputOutput {
    @xmlFlattened
    stringList: StringList,

    @xmlFlattened
    stringSet: StringSet,

    integerList: IntegerList,

    booleanList: BooleanList,
}

list StringList {
    member: String,
}
set StringSet {
    member: String,
}
list IntegerList {
    member: Integer,
}
list BooleanList {
    member: PrimitiveBoolean,
}