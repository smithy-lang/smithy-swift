$version: "2.0"

namespace smithy.swift.tests.maxRecursion

use smithy.protocols#rpcv2Cbor

@rpcv2Cbor
service MaxRecursionService {
    version: "2022-11-30"
    operations: [
        Recursive
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
