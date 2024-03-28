/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package waiters

import MockHttpRestJsonProtocolGenerator
import TestContext
import defaultSettings
import getFileContents
import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test
import software.amazon.smithy.build.FileManifest
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.codegen.core.WriterDelegator
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.ServiceShape
import software.amazon.smithy.swift.codegen.SwiftDelegator
import software.amazon.smithy.swift.codegen.SwiftSettings
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.core.SwiftCodegenContext
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.SwiftIntegration
import software.amazon.smithy.swift.codegen.model.expectShape
import software.amazon.smithy.swift.codegen.waiters.WaiterConfigGenerator
import software.amazon.smithy.waiters.WaitableTrait

class WaiterConfigGeneratorTests {

    @Test
    fun `renders correct function signature for waiter config`() {
        val context = setupTests("waiters.smithy", "com.test#TestHasWaiters")
        val contents = getFileContents(context.manifest, "/Test/Waiters.swift")
        val expected = """
            static func bucketExistsWaiterConfig() throws -> WaiterConfiguration<HeadBucketInput, HeadBucketOutput> {
        """.trimIndent()
        contents.shouldContainOnlyOnce(expected)
    }

    @Test
    fun `renders correct function return value for waiter config`() {
        val context = setupTests("waiters.smithy", "com.test#TestHasWaiters")
        val contents = getFileContents(context.manifest, "/Test/Waiters.swift")
        val expected = """
            return try WaiterConfiguration<HeadBucketInput, HeadBucketOutput>(acceptors: acceptors, minDelay: 7.0, maxDelay: 22.0)
        """.trimIndent()
        contents.shouldContainOnlyOnce(expected)
    }

    @Test
    fun `renders acceptor array for waiter config`() {
        val context = setupTests("waiters.smithy", "com.test#TestHasWaiters")
        val contents = getFileContents(context.manifest, "/Test/Waiters.swift")
        val expected = """
            let acceptors: [WaiterConfiguration<HeadBucketInput, HeadBucketOutput>.Acceptor] = [
        """.trimIndent()
        contents.shouldContainOnlyOnce(expected)
    }

    private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
        val context =
            TestContext.initContextFrom(smithyFile, serviceShapeId, MockHttpRestJsonProtocolGenerator()) { model ->
                model.defaultSettings(serviceShapeId, "Test", "2019-12-16", "Test")
            }
        context.generator.generateProtocolClient(context.generationCtx)
        val codegenContext = object : SwiftCodegenContext {
            override val model: Model = context.generationCtx.model
            override val symbolProvider: SymbolProvider = context.generationCtx.symbolProvider
            override val settings: SwiftSettings = context.generationCtx.settings
            override val fileManifest: FileManifest = context.manifest
            override val protocolGenerator: ProtocolGenerator = context.generator
            override val integrations: List<SwiftIntegration> = context.generationCtx.integrations

            override fun model(): Model {
                return model
            }

            override fun settings(): SwiftSettings {
                return settings
            }

            override fun symbolProvider(): SymbolProvider {
                return symbolProvider
            }

            override fun fileManifest(): FileManifest {
                return fileManifest
            }

            override fun writerDelegator(): WriterDelegator<SwiftWriter> {
                return SwiftDelegator(settings, model, fileManifest, symbolProvider, integrations)
            }

            override fun integrations(): MutableList<SwiftIntegration> {
                return integrations.toMutableList()
            }
        }
        val path = "Test/Waiters.swift"
        context.generationCtx.delegator.useFileWriter(path) { writer ->
            val service = codegenContext.model.expectShape<ServiceShape>(codegenContext.settings.service)
            val waitedOperation = service.allOperations
                .map { codegenContext.model.expectShape<OperationShape>(it) }.first()
            val waitableTrait = waitedOperation.allTraits.values.mapNotNull { it as? WaitableTrait }.first()
            val (waiterName, waiter) = waitableTrait.waiters.entries.first()
            val unit = WaiterConfigGenerator(writer, codegenContext, service, waitedOperation, waiterName, waiter)
            unit.render()
        }
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
