/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.aws.protocols.ec2query

import software.amazon.smithy.aws.traits.protocols.Ec2QueryTrait
import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.swift.codegen.aws.protocols.formurl.FormURLHttpBindingResolver
import software.amazon.smithy.swift.codegen.integration.DefaultHTTPProtocolCustomizations
import software.amazon.smithy.swift.codegen.integration.HttpBindingResolver
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.middlewares.ContentTypeMiddleware
import software.amazon.smithy.swift.codegen.integration.middlewares.OperationInputBodyMiddleware
import software.amazon.smithy.swift.codegen.middleware.MiddlewareRenderable
import software.amazon.smithy.swift.codegen.protocols.core.SmithyHTTPBindingProtocolGenerator

open class EC2QueryProtocolGenerator(
    customizations: DefaultHTTPProtocolCustomizations = EC2QueryCustomizations(),
    operationEndpointResolverMiddlewareFactory: ((ProtocolGenerator.GenerationContext, Symbol) -> MiddlewareRenderable)? = null,
    userAgentMiddlewareFactory: ((ProtocolGenerator.GenerationContext) -> MiddlewareRenderable)? = null,
    serviceErrorProtocolSymbolOverride: Symbol? = null,
    clockSkewProviderSymbolOverride: Symbol? = null,
    retryErrorInfoProviderSymbolOverride: Symbol? = null,
) : SmithyHTTPBindingProtocolGenerator(
        customizations,
        operationEndpointResolverMiddlewareFactory,
        userAgentMiddlewareFactory,
        serviceErrorProtocolSymbolOverride,
        clockSkewProviderSymbolOverride,
        retryErrorInfoProviderSymbolOverride,
    ) {
    override val defaultContentType = "application/x-www-form-urlencoded"
    override val protocol: ShapeId = Ec2QueryTrait.ID

    override fun getProtocolHttpBindingResolver(
        ctx: ProtocolGenerator.GenerationContext,
        contentType: String,
    ): HttpBindingResolver = FormURLHttpBindingResolver(ctx, contentType)

    override val shouldRenderEncodableConformance = true
    override val protocolTestsToIgnore =
        setOf(
            "SDKAppliedContentEncoding_ec2Query",
            "SDKAppendsGzipAndIgnoresHttpProvidedEncoding_ec2Query",
        )

    override fun addProtocolSpecificMiddleware(
        ctx: ProtocolGenerator.GenerationContext,
        operation: OperationShape,
    ) {
        super.addProtocolSpecificMiddleware(ctx, operation)
        operationMiddleware.removeMiddleware(operation, "OperationInputBodyMiddleware")
        operationMiddleware.appendMiddleware(operation, OperationInputBodyMiddleware(ctx.model, ctx.symbolProvider, true))

        val resolver = getProtocolHttpBindingResolver(ctx, defaultContentType)
        operationMiddleware.removeMiddleware(operation, "ContentTypeMiddleware")
        operationMiddleware.appendMiddleware(
            operation,
            ContentTypeMiddleware(ctx.model, ctx.symbolProvider, resolver.determineRequestContentType(operation), true),
        )
    }

    override fun httpBodyMembers(
        ctx: ProtocolGenerator.GenerationContext,
        shape: Shape,
    ): List<MemberShape> = shape.members().toList()
}
