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
        XmlWrappedList
    ]
}

@http(uri: "/XmlWrappedList", method: "POST")
operation XmlWrappedList {
    input: XmlWrappedListInputOutput,
    output: XmlWrappedListInputOutput
}



structure XmlWrappedListInputOutput {
    myGroceryList: GroceryList,
}

 list GroceryList {
     member: String,
 }