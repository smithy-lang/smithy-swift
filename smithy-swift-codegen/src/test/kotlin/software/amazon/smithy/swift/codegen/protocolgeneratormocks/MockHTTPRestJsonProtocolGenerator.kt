package software.amazon.smithy.swift.codegen.protocolgeneratormocks

/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import software.amazon.smithy.aws.traits.protocols.RestJson1Trait
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.swift.codegen.integration.DefaultHTTPProtocolCustomizations
import software.amazon.smithy.swift.codegen.integration.HTTPBindingProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.HttpProtocolTestGenerator
import software.amazon.smithy.swift.codegen.integration.HttpProtocolUnitTestErrorGenerator
import software.amazon.smithy.swift.codegen.integration.HttpProtocolUnitTestRequestGenerator
import software.amazon.smithy.swift.codegen.integration.HttpProtocolUnitTestResponseGenerator
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.isInHttpBody
import software.amazon.smithy.swift.codegen.requestandresponse.TestHttpProtocolClientGeneratorFactory

class MockRestJsonHTTPProtocolCustomizations : DefaultHTTPProtocolCustomizations()

class MockHTTPRestJsonProtocolGenerator : HTTPBindingProtocolGenerator(MockRestJsonHTTPProtocolCustomizations()) {
    override val defaultContentType: String = "application/json"
    override val protocol: ShapeId = RestJson1Trait.ID
    override val httpProtocolClientGeneratorFactory = TestHttpProtocolClientGeneratorFactory()
    override val shouldRenderEncodableConformance = false

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
            .filter { it.isInHttpBody() }
            .toList()
}
