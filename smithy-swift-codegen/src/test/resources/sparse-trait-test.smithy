$version: "1.0"
namespace smithy.example

use aws.protocols#restJson1

service Example {
    version: "1.0.0",
    operations: [
        JsonLists,
        JsonMaps
    ]
}

@idempotent
@http(uri: "/JsonLists", method: "PUT")
operation JsonLists {
    input: JsonListsInputOutput,
    output: JsonListsInputOutput
}

structure JsonListsInputOutput {
    stringList: StringList,
    sparseStringList: SparseStringList,
    booleanList: BooleanList,
    stringSet: StringSet,
    integerList: IntegerList,
    timestampList: TimestampList,
    nestedStringList: NestedStringList
}

list StringList {
    member: String
}

list NestedStringList {
    member: StringList
}

list BooleanList {
    member: Boolean
}

set StringSet {
    member: String
}

list IntegerList {
    member: Integer
}

list TimestampList {
    member: Timestamp
}

@sparse
list SparseStringList {
    member: String
}



@http(uri: "/JsonMaps", method: "POST")
operation JsonMaps {
    input: JsonMapsInputOutput,
    output: JsonMapsInputOutput
}

structure JsonMapsInputOutput {
    denseStructMap: DenseStructMap,
    sparseStructMap: SparseStructMap,
    denseNumberMap: DenseNumberMap,
    denseBooleanMap: DenseBooleanMap,
    denseStringMap: DenseStringMap,
    sparseNumberMap: SparseNumberMap,
    sparseBooleanMap: SparseBooleanMap,
    sparseStringMap: SparseStringMap,
}

structure GreetingStruct {
    hi: String
}

map DenseStructMap {
    key: String,
    value: GreetingStruct
}

@sparse
map SparseStructMap {
    key: String,
    value: GreetingStruct
}

map DenseBooleanMap {
    key: String,
    value: Boolean
}

map DenseNumberMap {
    key: String,
    value: Integer
}

map DenseStringMap {
    key: String,
    value: String
}

@sparse
map SparseStringMap {
    key: String,
    value: String
}

@sparse
map SparseBooleanMap {
    key: String,
    value: Boolean
}

@sparse
map SparseNumberMap {
    key: String,
    value: Integer
}