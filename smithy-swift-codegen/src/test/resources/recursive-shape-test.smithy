$version: "1.0"
namespace smithy.example

service Example {
    version: "1.0.0",
    operations: [
        RecursiveShapes
    ]
}

operation RecursiveShapes {
    input: RecursiveShapesInputOutput,
    output: RecursiveShapesInputOutput
}

structure RecursiveShapesInputOutput {
    nested: RecursiveShapesInputOutputNested1
}

structure RecursiveShapesInputOutputNested1 {
    foo: String,
    nested: RecursiveShapesInputOutputNested2
}

structure RecursiveShapesInputOutputNested2 {
    bar: String,
    recursiveMember: RecursiveShapesInputOutputNested1,
}

structure RecursiveShapesInputOutputLists {
    nested: RecursiveShapesInputOutputNestedList1
}

structure RecursiveShapesInputOutputNestedList1 {
    foo: String,
    recursiveList: RecursiveList
}


list RecursiveList {
    member: RecursiveShapesInputOutputNested2
}
