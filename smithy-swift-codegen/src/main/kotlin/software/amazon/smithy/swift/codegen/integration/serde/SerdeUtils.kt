package software.amazon.smithy.swift.codegen.integration.serde

import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.utils.sdkId

class SerdeUtils {
    companion object {
        fun useSchemaBased(ctx: ProtocolGenerator.GenerationContext) =
            // This fun is temporary; it will be eliminated when all services/protocols are moved to schema-based
            // Right now this function only returns true for the 2 live rpcv2Cbor-based services.
            listOf("ARC Region switch", "CloudWatch").contains(ctx.service.sdkId)
    }
}
