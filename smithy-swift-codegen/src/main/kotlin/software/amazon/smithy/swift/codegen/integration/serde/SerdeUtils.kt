package software.amazon.smithy.swift.codegen.integration.serde

import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.ServiceShape
import software.amazon.smithy.protocol.traits.Rpcv2CborTrait
import software.amazon.smithy.swift.codegen.SwiftSettings
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.model.expectShape
import software.amazon.smithy.swift.codegen.model.hasTrait

class SerdeUtils {
    companion object {
        fun useSchemaBased(ctx: ProtocolGenerator.GenerationContext) =
            useSchemaBased(ctx.service)

        fun useSchemaBased(settings: SwiftSettings, model: Model) =
            useSchemaBased(model.expectShape<ServiceShape>(settings.service))

        private fun useSchemaBased(service: ServiceShape) =
            // This fun is temporary; it will be eliminated when all services/protocols are moved to schema-based
            // Right now this function only returns true for rpcv2Cbor based services
            service.hasTrait<Rpcv2CborTrait>()
    }
}
