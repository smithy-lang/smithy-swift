/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
package mocks

import TestHttpProtocolClientGeneratorFactory
import software.amazon.smithy.aws.traits.protocols.AwsJson1_1Trait
import software.amazon.smithy.model.pattern.UriPattern
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.model.traits.HttpTrait
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.DefaultHTTPProtocolCustomizations
import software.amazon.smithy.swift.codegen.integration.HTTPBindingProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.HttpBindingResolver
import software.amazon.smithy.swift.codegen.integration.HttpProtocolTestGenerator
import software.amazon.smithy.swift.codegen.integration.HttpProtocolUnitTestErrorGenerator
import software.amazon.smithy.swift.codegen.integration.HttpProtocolUnitTestRequestGenerator
import software.amazon.smithy.swift.codegen.integration.HttpProtocolUnitTestResponseGenerator
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.protocols.core.StaticHttpBindingResolver
import software.amazon.smithy.swift.codegen.integration.serde.struct.StructDecodeGenerator
import software.amazon.smithy.swift.codegen.integration.serde.struct.StructEncodeGenerator
import software.amazon.smithy.swift.codegen.model.ShapeMetadata

class MockJsonHttpBindingResolver(
    private val context: ProtocolGenerator.GenerationContext,
    private val defaultContentType: String
) : StaticHttpBindingResolver(context, awsJsonHttpTrait, defaultContentType) {

    companion object {
        private val awsJsonHttpTrait: HttpTrait = HttpTrait
            .builder()
            .code(200)
            .method("POST")
            .uri(UriPattern.parse("/"))
            .build()
    }
}
class MockAWSJson11Customizations() : DefaultHTTPProtocolCustomizations() {
    override fun renderEventStreamAttributes(
        ctx: ProtocolGenerator.GenerationContext,
        writer: SwiftWriter,
        op: OperationShape,
    ) {
        // Not yet implemented
        return
    }
}

class MockHTTPAWSJson11ProtocolGenerator() : HTTPBindingProtocolGenerator(MockAWSJson11Customizations()) {
    override val defaultContentType: String = "application/json"
    override val protocol: ShapeId = AwsJson1_1Trait.ID
    override fun generateProtocolUnitTests(ctx: ProtocolGenerator.GenerationContext): Int {
        val requestTestBuilder = HttpProtocolUnitTestRequestGenerator.Builder()
        val responseTestBuilder = HttpProtocolUnitTestResponseGenerator.Builder()
        val errorTestBuilder = HttpProtocolUnitTestErrorGenerator.Builder()
        return HttpProtocolTestGenerator(
            ctx,
            requestTestBuilder,
            responseTestBuilder,
            errorTestBuilder,
            customizations,
            operationMiddleware,
            getProtocolHttpBindingResolver(ctx, defaultContentType),
        ).generateProtocolTests()
    }

    override val httpProtocolClientGeneratorFactory = TestHttpProtocolClientGeneratorFactory()
    override val shouldRenderEncodableConformance = false

    override fun renderStructEncode(
        ctx: ProtocolGenerator.GenerationContext,
        shapeContainingMembers: Shape,
        shapeMetadata: Map<ShapeMetadata, Any>,
        members: List<MemberShape>,
        writer: SwiftWriter,
        defaultTimestampFormat: TimestampFormatTrait.Format,
        path: String?
    ) {
        val encodeGenerator = StructEncodeGenerator(ctx, shapeContainingMembers, members, shapeMetadata, writer)
        encodeGenerator.render()
    }
    override fun renderStructDecode(
        ctx: ProtocolGenerator.GenerationContext,
        shapeContainingMembers: Shape,
        shapeMetadata: Map<ShapeMetadata, Any>,
        members: List<MemberShape>,
        writer: SwiftWriter,
        defaultTimestampFormat: TimestampFormatTrait.Format,
        path: String
    ) {
        StructDecodeGenerator(ctx, shapeContainingMembers, members, shapeMetadata, writer).render()
    }

    override fun addProtocolSpecificMiddleware(ctx: ProtocolGenerator.GenerationContext, operation: OperationShape) {
        // Intentionally empty
    }

    override fun getProtocolHttpBindingResolver(ctx: ProtocolGenerator.GenerationContext, defaultContentType: String):
        HttpBindingResolver = MockJsonHttpBindingResolver(ctx, defaultContentType)
}
