$version: "2.0"

namespace smithy.swift.tests.AWSJSON

use aws.protocols#awsJson1_0

@awsJson1_0
service AWSJSON {
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

    requiredTimestamps: RequiredTimestampsStructure

    requiredEnums: RequiredEnumsStructure
}

// Timestamp format is placed on these target shapes, not on the members that
// target them, to match the modeling used by the service in awslabs/aws-sdk-swift#2220.
@timestampFormat("date-time")
timestamp DateTimeTimestamp

@timestampFormat("http-date")
timestamp HTTPDateTimestamp

@timestampFormat("epoch-seconds")
timestamp EpochSecondsTimestamp

structure RequiredTimestampsStructure {
    @required
    dateTime: DateTimeTimestamp

    @required
    httpDate: HTTPDateTimestamp

    @required
    epochSeconds: EpochSecondsTimestamp
}

enum RequiredEnum {
    A = "a"
}

intEnum RequiredIntEnum {
    ONE = 1
}

structure RequiredEnumsStructure {
    @required
    enum: RequiredEnum

    @required
    intEnum: RequiredIntEnum
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
