$version: "1.0"

namespace aws.protocoltests.restxml

use aws.api#service
use aws.protocols#restXml
use smithy.test#httpRequestTests
use smithy.test#httpResponseTests

@service(sdkId: "Rest Xml blobs")
@restXml
service RestXml {
    version: "2019-12-16",
    operations: [
        XmlBlobs,
        XmlBlobsNested
    ]
}

@http(uri: "/XmlBlobs", method: "POST")
operation XmlBlobs {
    input: XmlBlobsInputOutput,
    output: XmlBlobsInputOutput
}


structure XmlBlobsInputOutput {
    data: Blob
}



@http(uri: "/XmlBlobsNested", method: "POST")
operation XmlBlobsNested {
    input: XmlBlobsNestedInputOutput,
    output: XmlBlobsNestedInputOutput
}

structure XmlBlobsNestedInputOutput {
    nestedBlobList: NestedNestedBlobList
}

list NestedNestedBlobList {
    member: NestedBlobList
}

list NestedBlobList {
    member: Blob
}
