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
    @deprecated
    string: String,
    structWithDeprecatedTrait: StructWithDeprecatedTrait,
    structSincePropertySet: StructSincePropertySet
}

@deprecated(message: "This shape is no longer used.", since: "1.3")
structure StructWithDeprecatedTrait {}

@deprecated(since: "2019-03-21")
structure StructSincePropertySet {}