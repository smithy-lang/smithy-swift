$version: "2.0"

namespace smithy.swift.tests

use aws.protocols#awsJson1_0

@awsJson1_0
service AWSJSONService {
    version: "2022-11-30"
    operations: [
        JSONName
        SerdeOperation
    ]
}

operation JSONName {
    input: JSONNameInput
    output: JSONNameOutput
}

structure JSONNameInput {
    @jsonName("modified")
    original: String
}

structure JSONNameOutput {
    @jsonName("modified")
    original: String
}

operation SerdeOperation {
    input: SerdeOperationInput
    output: SerdeOperationOutput
}

structure SerdeOperationInput {
    structure: SerdeOperationStructure
    union: SerdeOperationUnion
    string: String
    blob: Blob
    list: IntegerList
    map: IntegerMap
    double: Double
    boolean: Boolean
    sparseList: SparseIntegerList
}

structure SerdeOperationOutput {}

structure SerdeOperationStructure {
    a: String
    b: Integer
    c: Boolean
}

union SerdeOperationUnion {
    x: String
    y: Integer
    z: Boolean
}

list IntegerList {
    member: Integer
}

map IntegerMap {
    key: String
    value: Integer
}

@sparse
list SparseIntegerList {
    member: Integer
}
