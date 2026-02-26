package software.amazon.smithy.swift.codegen.integration.serde

import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator

class SerdeUtils {
    companion object {
        fun useSchemaBased(ctx: ProtocolGenerator.GenerationContext) =
            // This fun is temporary; it will be eliminated when all services/protocols are moved to schema-based
            // Right now this function always returns false.  Will return true for certain protocols as they
            // are implemented.
            false
    }
}
