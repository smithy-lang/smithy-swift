/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package waiters

import MockHttpRestJsonProtocolGenerator
import TestContext
import defaultSettings
import getFileContents
import io.kotest.matchers.collections.shouldContain
import io.kotest.matchers.collections.shouldNotContain
import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.swift.codegen.SwiftSettings
import software.amazon.smithy.swift.codegen.core.CodegenContext
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.SwiftIntegration
import software.amazon.smithy.swift.codegen.waiters.WaiterGenerator
import kotlin.io.path.Path

class WaiterGeneratorTests {

    @Test
    fun `renders a waiters extension on protocol`() {
        val context = setupTests("waiters.smithy", "com.test#TestHasWaiters")
        val contents = getFileContents(context.manifest, "/Test/Waiters.swift")
        val expected = """
            #if swift(>=5.7)
            extension TestClientProtocol {
        """.trimIndent()
        contents.shouldContainOnlyOnce(expected)
        val expected2 = """
            }
            #endif
        """.trimIndent()
        contents.shouldContainOnlyOnce(expected2)
    }

    @Test
    fun `renders a waiter config into extension`() {
        val context = setupTests("waiters.smithy", "com.test#TestHasWaiters")
        val contents = getFileContents(context.manifest, "/Test/Waiters.swift")
        val expected = """
            return try WaiterConfiguration<HeadBucketInput, HeadBucketOutputResponse>(acceptors: acceptors, minDelay: 7.0, maxDelay: 22.0)
        """.trimIndent()
        contents.shouldContainOnlyOnce(expected)
    }

    @Test
    fun `renders a waiter method into extension`() {
        val context = setupTests("waiters.smithy", "com.test#TestHasWaiters")
        val contents = getFileContents(context.manifest, "/Test/Waiters.swift")
        val expected = """
            public func waitUntilBucketExists(options: WaiterOptions, input: HeadBucketInput) async throws -> WaiterOutcome<HeadBucketOutputResponse> {
        """.trimIndent()
        contents.shouldContainOnlyOnce(expected)
    }

    @Test
    fun `renders a WaiterTypedError extension if the waiter has errorType acceptors`() {
        val context = setupTests("waiters.smithy", "com.test#TestHasWaiters")
        val filePaths = context.manifest.files
        filePaths.shouldContain(Path("/Test/models/HeadBucketOutputError+WaiterTypedError.swift"))
    }

    @Test
    fun `does not render a WaiterTypedError extension if the waiter has no errorType acceptors`() {
        val context = setupTests("waiters-no-error-type.smithy", "com.test#TestHasWaiters")
        val filePaths = context.manifest.files
        filePaths.shouldNotContain(Path("/Test/models/HeadBucketOutputError+WaiterTypedError.swift"))
    }

    private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
        val context =
            TestContext.initContextFrom(smithyFile, serviceShapeId, MockHttpRestJsonProtocolGenerator()) { model ->
                model.defaultSettings(serviceShapeId, "Test", "2019-12-16", "Test")
            }
        context.generator.generateProtocolClient(context.generationCtx)
        val codegenContext = object : CodegenContext {
            override val model: Model = context.generationCtx.model
            override val symbolProvider: SymbolProvider = context.generationCtx.symbolProvider
            override val settings: SwiftSettings = context.generationCtx.settings
            override val protocolGenerator: ProtocolGenerator? = context.generator
            override val integrations: List<SwiftIntegration> = context.generationCtx.integrations
        }
        val path = "Test/Waiters.swift"
        context.generationCtx.delegator.useFileWriter(path) { writer ->
            val unit = WaiterGenerator(codegenContext, context.generationCtx, context.generationCtx.delegator)
            unit.render()
        }
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
