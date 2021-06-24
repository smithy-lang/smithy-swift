$version: "1.0"
namespace smithy.example

use aws.protocols#restJson1

service Example {
    version: "1.0.0",
    operations: [
        HashableShapes
    ]
}

operation HashableShapes {
    input: HashableInput,
    output: HashableOutput
}

structure HashableInput {
    bar: String,
    set: HashableSet
}

set HashableSet {
    member: HashableStructure
}

structure HashableStructure {
    foo: String,
    baz: NestedHashableStructure
}

structure NestedHashableStructure {
    bar: String,
    quz: Integer
}

structure HashableOutput {
    quz: String
}