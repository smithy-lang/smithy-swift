/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
package software.amazon.smithy.swift.codegen.aws.protocols.restjson

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.aws.traits.protocols.RestJson1Trait
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.swift.codegen.integration.DefaultHTTPProtocolCustomizations
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.isInHttpBody
import software.amazon.smithy.swift.codegen.middleware.MiddlewareRenderable
import software.amazon.smithy.swift.codegen.protocols.core.SmithyHTTPBindingProtocolGenerator

open class RestJson1ProtocolGenerator(
    customizations: DefaultHTTPProtocolCustomizations = RestJson1Customizations(),
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
    override val defaultContentType = "application/json"
    override val protocol: ShapeId = RestJson1Trait.ID
    override val protocolTestsToIgnore =
        setOf(
            "SDKAppliedContentEncoding_restJson1",
            "SDKAppendedGzipAfterProvidedEncoding_restJson1",
        )

    override fun httpBodyMembers(
        ctx: ProtocolGenerator.GenerationContext,
        shape: Shape,
    ): List<MemberShape> =
        shape
            .members()
            .filter { it.isInHttpBody() }
            .toList()
}
