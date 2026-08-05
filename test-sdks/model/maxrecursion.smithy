$version: "2.0"

namespace smithy.swift.tests.MaxRecursion

use aws.protocols#awsJson1_0
use smithy.protocols#rpcv2Cbor

@rpcv2Cbor
@awsJson1_0
service MaxRecursion {
    version: "2022-11-30"
    operations: [
        Recursive
        DeeplyNested
    ]
}

operation Recursive {
    input: RecursiveInputOutput
    output: RecursiveInputOutput
}

structure RecursiveInputOutput {
    nested: RecursiveInputOutput
    nestedList: NestedList
    nestedMap: NestedMap
}

list NestedList {
    member: RecursiveInputOutput
}

map NestedMap {
    key: String
    value: RecursiveInputOutput
}

operation DeeplyNested {
    input: DeeplyNestedInputOutput
    output: DeeplyNestedInputOutput
}

structure DeeplyNestedInputOutput {
    list: List1
    map: Map1
}

list List1 {
    member: List2
}

list List2 {
    member: List3
}

list List3 {
    member: String
}

map Map1 {
    key: String
    value: Map2
}

map Map2 {
    key: String
    value: Map3
}

map Map3 {
    key: String
    value: String
}
