$version: "1.0"

namespace aws.protocoltests.restxml

use aws.api#service
use aws.protocols#restXml
use smithy.test#httpRequestTests
use smithy.test#httpResponseTests

@service(sdkId: "Rest Xml List")
@restXml
service RestXml {
    version: "2019-12-16",
    operations: [
        XmlEmptyLists
    ]
}

@idempotent
@http(uri: "/XmlEmptyLists", method: "PUT")
@tags(["client-only"])
operation XmlEmptyLists {
    input: XmlListsInputOutput,
    output: XmlListsInputOutput,
}

structure XmlListsInputOutput {
    stringList: StringList,

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