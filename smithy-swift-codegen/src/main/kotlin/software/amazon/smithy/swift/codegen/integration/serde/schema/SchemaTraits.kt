package software.amazon.smithy.swift.codegen.integration.serde.schema

val permittedTraitIDs: Set<String> =
    setOf(
        "smithy.api#sparse",
        "smithy.api#enumValue",
        "smithy.api#jsonName",
        "smithy.api#required",
        "smithy.api#default",
        "smithy.api#timestampFormat",
        "smithy.api#httpPayload",
    )
