package software.amazon.smithy.swift.codegen.integration.serde

import software.amazon.smithy.aws.traits.protocols.RestXmlTrait
import software.amazon.smithy.model.shapes.ServiceShape
import software.amazon.smithy.protocol.traits.Rpcv2CborTrait
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.model.hasTrait

class SerdeUtils {
    companion object {
        fun useSchemaBased(ctx: ProtocolGenerator.GenerationContext) =
            useSchemaBased(ctx.service)

        fun useSchemaBased(service: ServiceShape) =
            // This fun is temporary; it will be eliminated when all services/protocols are moved to schema-based
            service.hasTrait<Rpcv2CborTrait>() || service.hasTrait<RestXmlTrait>()
    }
}
