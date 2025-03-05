package software.amazon.smithy.swift.codegen.waiters

/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.booleans.shouldBeFalse
import io.kotest.matchers.booleans.shouldBeTrue
import io.kotest.matchers.collections.shouldContain
import io.kotest.matchers.collections.shouldNotContain
import org.junit.jupiter.api.Test
import software.amazon.smithy.build.FileManifest
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.codegen.core.WriterDelegator
import software.amazon.smithy.model.Model
import software.amazon.smithy.swift.codegen.SwiftDelegator
import software.amazon.smithy.swift.codegen.SwiftSettings
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.TestContext
import software.amazon.smithy.swift.codegen.core.SwiftCodegenContext
import software.amazon.smithy.swift.codegen.defaultSettings
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.SwiftIntegration
import software.amazon.smithy.swift.codegen.protocolgeneratormocks.MockHTTPRestJsonProtocolGenerator
import kotlin.io.path.Path

class WaiterIntegrationTests {
    @Test
    fun `generator not enabled for service without waiters`() {
        val context = setupTests("waiters-none.smithy", "com.test#TestHasNoWaiters")
        WaiterIntegration().enabledForService(context.generationCtx.model, context.generationCtx.settings).shouldBeFalse()
    }

    @Test
    fun `generator enabled for service with waiters`() {
        val context = setupTests("waiters.smithy", "com.test#TestHasWaiters")
        WaiterIntegration().enabledForService(context.generationCtx.model, context.generationCtx.settings).shouldBeTrue()
    }

    @Test
    fun `renders waiters swift file for service with waiters`() {
        val context = setupTests("waiters.smithy", "com.test#TestHasWaiters")
        val filePaths = context.manifest.files
        filePaths.shouldContain(Path("/Sources/Test/Waiters.swift"))
    }

    @Test
    fun `renders no waiters Swift file for service without waiters`() {
        val context = setupTests("waiters-none.smithy", "com.test#TestHasNoWaiters")
        val filePaths = context.manifest.files
        filePaths.shouldNotContain(Path("Sources/Test/Waiters.swift"))
    }

    private fun setupTests(
        smithyFile: String,
        serviceShapeId: String,
    ): TestContext {
        val context =
            TestContext.initContextFrom(smithyFile, serviceShapeId, MockHTTPRestJsonProtocolGenerator()) { model ->
                model.defaultSettings(serviceShapeId, "Test", "2019-12-16", "Test")
            }
        context.generator.generateProtocolClient(context.generationCtx)
        val codegenContext =
            object : SwiftCodegenContext {
                override val model: Model = context.generationCtx.model
                override val symbolProvider: SymbolProvider = context.generationCtx.symbolProvider
                override val settings: SwiftSettings = context.generationCtx.settings
                override val fileManifest: FileManifest = context.manifest
                override val protocolGenerator: ProtocolGenerator? = context.generator
                override val integrations: List<SwiftIntegration> = context.generationCtx.integrations

                override fun model(): Model = model

                override fun settings(): SwiftSettings = settings

                override fun symbolProvider(): SymbolProvider = symbolProvider

                override fun fileManifest(): FileManifest = fileManifest

                override fun writerDelegator(): WriterDelegator<SwiftWriter> =
                    SwiftDelegator(settings, model, fileManifest, symbolProvider, integrations)

                override fun integrations(): MutableList<SwiftIntegration> = integrations.toMutableList()
            }
        val unit = WaiterIntegration()
        if (unit.enabledForService(codegenContext.model, codegenContext.settings)) {
            unit.writeAdditionalFiles(codegenContext, context.generationCtx, context.generationCtx.delegator)
        }
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
