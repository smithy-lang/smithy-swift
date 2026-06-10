$version: "2.0"
namespace smithy.example

use aws.protocols#restJson1

service Example {
    version: "1.0.0",
    operations: [
        DefaultNullOverride
    ]
}

@idempotent
@http(uri: "/DefaultNullOverride", method: "PUT")
operation DefaultNullOverride {
    input: DefaultNullOverrideInput,
    output: DefaultNullOverrideOutput
}

/// A boolean target shape that carries a @default of false.
@default(false)
boolean DefaultingBoolean

@input
structure DefaultNullOverrideInput {
    /// Member-level @default: null overrides the target's @default(false),
    /// so this member has no default and must generate `= nil`.
    overriddenToNull: DefaultingBoolean = null

    /// Member restates the target's @default(false). Generates `= false`.
    keepsDefault: DefaultingBoolean = false
}

structure DefaultNullOverrideOutput {
    overriddenToNull: DefaultingBoolean = null
}
