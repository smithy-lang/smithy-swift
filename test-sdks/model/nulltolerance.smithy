$version: "2.0"

namespace smithy.swift.tests.NullTolerance

use aws.protocols#awsJson1_0

@awsJson1_0
service NullTolerance {
    version: "2022-11-30"
    operations: [
        NullToleranceTest
    ]
}

operation NullToleranceTest {
    input: NullToleranceTestInput
    output: NullToleranceTestOutput
}

structure NullToleranceTestInput {}

structure NullToleranceTestOutput {
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
