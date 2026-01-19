package software.amazon.smithy.swift.codegen.protocols.rpcv2cbor

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.model.traits.UnitTypeTrait
import software.amazon.smithy.protocol.traits.Rpcv2CborTrait
import software.amazon.smithy.swift.codegen.SyntheticClone
import software.amazon.smithy.swift.codegen.integration.DefaultHTTPProtocolCustomizations
import software.amazon.smithy.swift.codegen.integration.HttpBindingResolver
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.middleware.MiddlewareRenderable
import software.amazon.smithy.swift.codegen.model.getTrait
import software.amazon.smithy.swift.codegen.model.targetOrSelf

class RpcV2CborProtocolGenerator(
    customizations: DefaultHTTPProtocolCustomizations = RpcV2CborCustomizations(),
    operationEndpointResolverMiddlewareFactory: ((ProtocolGenerator.GenerationContext, Symbol) -> MiddlewareRenderable)? = null,
    userAgentMiddlewareFactory: ((ProtocolGenerator.GenerationContext) -> MiddlewareRenderable)? = null,
) : SmithyHTTPBindingProtocolGenerator(
        customizations,
        operationEndpointResolverMiddlewareFactory,
        userAgentMiddlewareFactory,
    ) {
    override val defaultContentType = "application/cbor"
    override val protocol: ShapeId = Rpcv2CborTrait.ID
    override val shouldRenderEncodableConformance = true

    override fun getProtocolHttpBindingResolver(
        ctx: ProtocolGenerator.GenerationContext,
        defaultContentType: String,
    ): HttpBindingResolver = RPCV2CBORHttpBindingResolver(ctx, defaultContentType)

    override fun addProtocolSpecificMiddleware(
        ctx: ProtocolGenerator.GenerationContext,
        operation: OperationShape,
    ) {
        super.addProtocolSpecificMiddleware(ctx, operation)

        // These are performed by the schema-based rpcv2cbor configurator.  Not needed here.
        operationMiddleware.removeMiddleware(operation, "OperationInputBodyMiddleware")
        operationMiddleware.removeMiddleware(operation, "DeserializeMiddleware")
        operationMiddleware.removeMiddleware(operation, "OperationInputUrlPathMiddleware")
        operationMiddleware.removeMiddleware(operation, "ContentTypeMiddleware")
        operationMiddleware.removeMiddleware(operation, "ContentLengthMiddleware")
        operationMiddleware.removeMiddleware(operation, "ContentLengthMiddleware")
    }

    override fun httpBodyMembers(
        ctx: ProtocolGenerator.GenerationContext,
        shape: Shape,
    ): List<MemberShape> =
        shape
            .members()
            .toList()

    /**
     * @return whether the operation input does _not_ target the unit shape ([UnitTypeTrait.UNIT])
     */
    private fun OperationShape.hasHttpBody(ctx: ProtocolGenerator.GenerationContext): Boolean {
        val input =
            ctx.model.expectShape(inputShape).targetOrSelf(ctx.model).let {
                // If the input has been synthetically cloned from the original (most likely),
                // pull the archetype and check _that_
                it.getTrait<SyntheticClone>()?.let { clone ->
                    ctx.model.expectShape(clone.archetype).targetOrSelf(ctx.model)
                } ?: it
            }

        return input.id != UnitTypeTrait.UNIT
    }
}
