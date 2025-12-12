package software.amazon.smithy.swift.codegen.integration.serde.schema

val permittedTraitIDs: Set<String> =
    setOf(
        "smithy.api#sparse",
        "smithy.api#input",
        "smithy.api#output",
        "smithy.api#error",
        "smithy.api#enumValue",
        "smithy.api#jsonName",
        "smithy.api#required",
        "smithy.api#default",
        "smithy.api#timestampFormat",
    )
