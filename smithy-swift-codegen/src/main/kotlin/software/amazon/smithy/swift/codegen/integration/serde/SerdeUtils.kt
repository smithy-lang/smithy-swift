package software.amazon.smithy.swift.codegen.integration.serde

import software.amazon.smithy.aws.traits.protocols.AwsJson1_0Trait
import software.amazon.smithy.aws.traits.protocols.AwsJson1_1Trait
import software.amazon.smithy.protocol.traits.Rpcv2CborTrait
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.model.hasTrait

class SerdeUtils {
    companion object {
        fun useSchemaBased(ctx: ProtocolGenerator.GenerationContext) =
            // This fun is temporary; it will be eliminated when all services/protocols are moved to schema-based
            // Right now this function only returns true for rpcv2Cbor or AwsJson 1.0 / 1.1 based services
            ctx.service.hasTrait<Rpcv2CborTrait>() || ctx.service.hasTrait<AwsJson1_0Trait>() || ctx.service.hasTrait<AwsJson1_1Trait>()
    }
}
