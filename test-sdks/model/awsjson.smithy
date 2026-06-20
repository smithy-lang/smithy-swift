$version: "2.0"

namespace smithy.swift.tests

use aws.protocols#awsJson1_0

@awsJson1_0
service AWSJSONService {
    version: "2022-11-30"
    operations: [
        JSONName
        NullTolerance
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

operation NullTolerance {
    input: NullToleranceInput
    output: NullToleranceOutput
}

structure NullToleranceInput {}

structure NullToleranceOutput {
    list: NullToleranceList
    map: NullToleranceMap
    sparseList: SparseNullToleranceList
    sparseMap: SparseNullToleranceMap
}

list NullToleranceList {
    member: Integer
}

map NullToleranceMap {
    key: String
    value: Integer
}

@sparse
list SparseNullToleranceList {
    member: Integer
}

@sparse
map SparseNullToleranceMap {
    key: String
    value: Integer
}
