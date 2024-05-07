$version: "1.0"
namespace smithy.example

use aws.protocols#restJson1

service Example {
    version: "1.0.0",
    operations: [
        OperationWithDeprecatedTrait
    ]
}

@idempotent
@http(uri: "/OperationWithDeprecatedTrait", method: "PUT")
operation OperationWithDeprecatedTrait {
    input: OperationWithDeprecatedTraitInputOutput,
    output: OperationWithDeprecatedTraitInputOutput
}

@deprecated(message: "This shape is no longer used.", since: "1.3")
structure OperationWithDeprecatedTraitInputOutput {
    bool: Boolean,
    intVal: Integer,
    @deprecated(since: "2024-11-12")
    string: String,
    structWithDeprecatedTrait: StructWithDeprecatedTrait,
    structSincePropertySet: StructSincePropertySet,
    foo: Foo
}

@deprecated(message: "This shape is no longer used.", since: "1.3")
structure StructWithDeprecatedTrait {}

@deprecated(since: "2019-03-21")
structure StructSincePropertySet {}


structure Foo {
    @documentation("Test documentation with deprecated")
    baz: Baz,
    @documentation("Test documentation with deprecated")
    qux: Qux,
}

@deprecated
string Baz

string Qux