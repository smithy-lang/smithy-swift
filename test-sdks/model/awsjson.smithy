$version: "2.0"

namespace smithy.swift.tests

use aws.protocols#awsJson1_0

@awsJson1_0
service AWSJSONService {
    version: "2022-11-30"
    operations: [
        SerdeOperation
    ]
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

    document: Document

    myDocument: MyDocument

    nestedMap: OuterNestedMap

    nestedList: OuterNestedList

    @timestampFormat("date-time")
    dateTimeTimestamp: Timestamp

    @timestampFormat("http-date")
    httpDateTimestamp: Timestamp

    @timestampFormat("epoch-seconds")
    epochSecondsTimestamp: Timestamp
}

structure SerdeOperationOutput {
    @timestampFormat("date-time")
    dateTimeTimestamp: Timestamp

    @timestampFormat("http-date")
    httpDateTimestamp: Timestamp

    @timestampFormat("epoch-seconds")
    epochSecondsTimestamp: Timestamp
}

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

document MyDocument

map OuterNestedMap {
    key: String
    value: InnerNestedMap
}

map InnerNestedMap {
    key: String
    value: String
}

list OuterNestedList {
    member: InnerNestedList
}

list InnerNestedList {
    member: String
}
