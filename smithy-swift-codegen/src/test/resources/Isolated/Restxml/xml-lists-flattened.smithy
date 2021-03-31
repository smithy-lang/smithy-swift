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
        XmlFlattenedList
    ]
}

@http(uri: "/XmlFlattenedList", method: "POST")
operation XmlFlattenedList {
    input: XmlFlattenedListInputOutput,
    output: XmlFlattenedListInputOutput
}



structure XmlFlattenedListInputOutput {
    @xmlFlattened
    myGroceryList: GroceryList,
}

 list GroceryList {
     member: String,
 }