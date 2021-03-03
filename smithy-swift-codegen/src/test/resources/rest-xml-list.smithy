
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
        XmlListFlattened,
        XmlListNested
    ]
}

@http(uri: "/XmlListFlattened", method: "POST")
operation XmlListFlattened {
    input: XmlListFlattenedInputOutput,
    output: XmlListFlattenedInputOutput
}

@http(uri: "/XmlListNested", method: "POST")
operation XmlListNested {
    input: XmlListNestedInputOutput,
    output: XmlListNestedInputOutput
}


structure XmlListFlattenedInputOutput {
    @xmlFlattened
    myFlattenedList: GroceryList,
}

structure XmlListNestedInputOutput {
    myNestedList: GroceryList,
}

 list GroceryList {
     member: String,
 }