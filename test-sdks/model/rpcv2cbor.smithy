$version: "2.0"

namespace smithy.swift.tests

use smithy.protocols#rpcv2Cbor

@rpcv2Cbor
service RPCv2CBORService {
    version: "2022-11-30",
    operations: [
        GetWidget,
        Recursive,
    ]
}

operation GetWidget {
    input: GetWidgetInput
    output: GetWidgetOutput
}

@input
structure GetWidgetInput {
    sensitiveType: SensitiveType
}

@output
structure GetWidgetOutput {
    privateString: PrivateString
}

structure SensitiveType {
    publicString: String
    publicList: PublicList
    publicMap: PublicMap
    privateString: PrivateString
    privateList: PrivateList
    privateMap: PrivateMap
}

list PublicList {
    member: String
}

map PublicMap {
    key: String
    value: String
}

@sensitive
string PrivateString

list PrivateList {
    member: PrivateString
}

map PrivateMap {
    key: String
    value: PrivateString
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
