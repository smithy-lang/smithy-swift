/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.aws.protocols.awsjson

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.aws.traits.protocols.AwsJson1_0Trait
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.swift.codegen.integration.DefaultHTTPProtocolCustomizations
import software.amazon.smithy.swift.codegen.integration.HttpBindingResolver
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.isEventStreaming
import software.amazon.smithy.swift.codegen.integration.middlewares.ContentTypeMiddleware
import software.amazon.smithy.swift.codegen.integration.middlewares.OperationInputBodyMiddleware
import software.amazon.smithy.swift.codegen.middleware.MiddlewareRenderable
import software.amazon.smithy.swift.codegen.model.targetOrSelf
import software.amazon.smithy.swift.codegen.protocols.core.SmithyHTTPBindingProtocolGenerator

@Suppress("ktlint:standard:class-naming")
open class AWSJSON1_0ProtocolGenerator(
    customizations: DefaultHTTPProtocolCustomizations = AWSJSONCustomizations(),
    operationEndpointResolverMiddlewareFactory: ((ProtocolGenerator.GenerationContext, Symbol) -> MiddlewareRenderable)? = null,
    userAgentMiddlewareFactory: ((ProtocolGenerator.GenerationContext) -> MiddlewareRenderable)? = null,
    private val xAmzTargetMiddlewareFactory: ((ProtocolGenerator.GenerationContext) -> MiddlewareRenderable)? = null,
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
    override val defaultContentType = "application/x-amz-json-1.0"
    override val protocol: ShapeId = AwsJson1_0Trait.ID
    override val shouldRenderEncodableConformance: Boolean = true
    override val protocolTestsToIgnore =
        setOf(
            "SDKAppliedContentEncoding_awsJson1_0",
            "SDKAppendsGzipAndIgnoresHttpProvidedEncoding_awsJson1_0",
        )

    override fun getProtocolHttpBindingResolver(
        ctx: ProtocolGenerator.GenerationContext,
        defaultContentType: String,
    ): HttpBindingResolver = AWSJSONHttpBindingResolver(ctx, defaultContentType)

    override fun addProtocolSpecificMiddleware(
        ctx: ProtocolGenerator.GenerationContext,
        operation: OperationShape,
    ) {
        super.addProtocolSpecificMiddleware(ctx, operation)

        xAmzTargetMiddlewareFactory?.let { factory ->
            operationMiddleware.appendMiddleware(operation, factory(ctx))
        }

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
    ): List<MemberShape> =
        shape
            .members()
            .filter { !it.targetOrSelf(ctx.model).isEventStreaming }
            .toList()
}
