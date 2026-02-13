/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.aws.protocols.restxml

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.aws.traits.protocols.RestXmlTrait
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.swift.codegen.integration.DefaultHTTPProtocolCustomizations
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.isInHttpBody
import software.amazon.smithy.swift.codegen.middleware.MiddlewareRenderable
import software.amazon.smithy.swift.codegen.protocols.core.SmithyHTTPBindingProtocolGenerator

open class RestXmlProtocolGenerator(
    customizations: DefaultHTTPProtocolCustomizations = RestXmlCustomizations(),
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
    override val defaultContentType: String = "application/xml"
    override val protocol: ShapeId = RestXmlTrait.ID
    override val protocolTestsToIgnore: Set<String> =
        setOf(
            "S3DefaultAddressing",
            "S3VirtualHostAddressing",
            "S3VirtualHostDualstackAddressing",
            "S3VirtualHostAccelerateAddressing",
            "S3VirtualHostDualstackAccelerateAddressing",
            "S3OperationAddressingPreferred",
            "S3EscapeObjectKeyInUriLabel",
            "S3EscapePathObjectKeyInUriLabel",
            "SDKAppliedContentEncoding_restXml",
            "SDKAppendedGzipAfterProvidedEncoding_restXml",
            "S3PreservesEmbeddedDotSegmentInUriLabel",
            "S3PreservesLeadingDotSegmentInUriLabel",
        )

    override fun generateDeserializers(ctx: ProtocolGenerator.GenerationContext) {
        super.generateDeserializers(ctx)
        val errorShapes = resolveErrorShapes(ctx)
        for (shape in errorShapes) {
            renderCodableExtension(ctx, shape)
        }
    }

    override fun httpBodyMembers(
        ctx: ProtocolGenerator.GenerationContext,
        shape: Shape,
    ): List<MemberShape> =
        shape
            .members()
            .filter { it.isInHttpBody() }
            .toList()
}
