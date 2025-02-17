package software.amazon.smithy.swift.codegen.protocolgeneratormocks

/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import software.amazon.smithy.aws.traits.protocols.Ec2QueryTrait
import software.amazon.smithy.model.pattern.UriPattern
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.model.traits.HttpTrait
import software.amazon.smithy.swift.codegen.integration.DefaultHTTPProtocolCustomizations
import software.amazon.smithy.swift.codegen.integration.HTTPBindingProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.HttpBindingResolver
import software.amazon.smithy.swift.codegen.integration.HttpProtocolTestGenerator
import software.amazon.smithy.swift.codegen.integration.HttpProtocolUnitTestErrorGenerator
import software.amazon.smithy.swift.codegen.integration.HttpProtocolUnitTestRequestGenerator
import software.amazon.smithy.swift.codegen.integration.HttpProtocolUnitTestResponseGenerator
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.protocols.core.StaticHttpBindingResolver
import software.amazon.smithy.swift.codegen.requestandresponse.TestHttpProtocolClientGeneratorFactory

class MockEC2QueryHTTPProtocolCustomizations : DefaultHTTPProtocolCustomizations()

class MockEC2QueryHttpBindingResolver(
    private val context: ProtocolGenerator.GenerationContext,
    private val contentType: String,
) : StaticHttpBindingResolver(context, awsQueryHttpTrait, contentType) {
    companion object {
        private val awsQueryHttpTrait: HttpTrait =
            HttpTrait
                .builder()
                .code(200)
                .method("POST")
                .uri(UriPattern.parse("/"))
                .build()
    }
}

class MockHTTPEC2QueryProtocolGenerator : HTTPBindingProtocolGenerator(MockEC2QueryHTTPProtocolCustomizations()) {
    override val defaultContentType: String = "application/x-www-form-urlencoded"
    override val protocol: ShapeId = Ec2QueryTrait.ID
    override val httpProtocolClientGeneratorFactory = TestHttpProtocolClientGeneratorFactory()
    override val shouldRenderEncodableConformance = true

    override fun addProtocolSpecificMiddleware(
        ctx: ProtocolGenerator.GenerationContext,
        operation: OperationShape,
    ) {
        // Intentionally empty
    }

    override fun addUserAgentMiddleware(
        ctx: ProtocolGenerator.GenerationContext,
        operation: OperationShape,
    ) {
        // Intentionally empty
    }

    override fun getProtocolHttpBindingResolver(
        ctx: ProtocolGenerator.GenerationContext,
        defaultContentType: String,
    ): HttpBindingResolver = MockEC2QueryHttpBindingResolver(ctx, defaultContentType)

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
            getProtocolHttpBindingResolver(ctx, defaultContentType),
        ).generateProtocolTests()
    }

    override fun httpBodyMembers(
        ctx: ProtocolGenerator.GenerationContext,
        shape: Shape,
    ): List<MemberShape> =
        shape
            .members()
            .toList()
}
