$version: "1.0"

namespace aws.protocoltests.restxml

use aws.api#service
use aws.protocols#restXml
use smithy.test#httpRequestTests
use smithy.test#httpResponseTests

@service(sdkId: "Rest Xml recursive nested")
@restXml
service RestXml {
    version: "2019-12-16",
    operations: [
        XmlNestedRecursiveShapes
    ]
}

@idempotent
@http(uri: "/XmlNestedRecursiveShapes", method: "PUT")
operation XmlNestedRecursiveShapes {
    input: NestedRecursiveShapesInputOutput,
    output: NestedRecursiveShapesInputOutput
}

structure NestedRecursiveShapesInputOutput {
    nestedRecursiveList: NestedNestedRecursiveShapesList
}

list NestedNestedRecursiveShapesList {
    member: NestedRecursiveShapesList
}

list NestedRecursiveShapesList {
    member: RecursiveShapesInputOutputNested1
}


structure RecursiveShapesInputOutputNested1 {
    foo: String,
    nested: RecursiveShapesInputOutputNested2
}

structure RecursiveShapesInputOutputNested2 {
    bar: String,
    recursiveMember: RecursiveShapesInputOutputNested1,
}

