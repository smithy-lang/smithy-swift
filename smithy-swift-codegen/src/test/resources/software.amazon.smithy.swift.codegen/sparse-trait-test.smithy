$version: "1.0"
namespace smithy.example

use aws.protocols#restJson1

service Example {
    version: "1.0.0",
    operations: [
        JsonLists
    ]
}

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