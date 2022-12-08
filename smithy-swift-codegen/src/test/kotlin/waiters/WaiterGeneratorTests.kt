package waiters/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import MockHttpRestJsonProtocolGenerator
import TestContext
import defaultSettings
import io.kotest.matchers.booleans.shouldBeFalse
import io.kotest.matchers.booleans.shouldBeTrue
import io.kotest.matchers.collections.shouldContain
import io.kotest.matchers.collections.shouldNotContain
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
    fun testGeneratorNotEnabledForServiceWithoutWaiters() {
        val context = setupTests("waiters-none.smithy", "com.test#TestHasNoWaiters")
        WaiterGenerator().enabledForService(context.generationCtx.model, context.generationCtx.settings).shouldBeFalse()
    }

    @Test
    fun testGeneratorEnabledForServiceWithWaiters() {
        val context = setupTests("waiters.smithy", "com.test#TestHasWaiters")
        WaiterGenerator().enabledForService(context.generationCtx.model, context.generationCtx.settings).shouldBeTrue()
    }

    @Test
    fun testRendersWaitersSwiftFileForServiceWithWaiters() {
        val context = setupTests("waiters.smithy", "com.test#TestHasWaiters")
        val filePaths = context.manifest.files
        filePaths.shouldContain(Path("/Test/Waiters.swift"))
    }

    @Test
    fun testRendersNoWaitersSwiftFileForServiceWithoutWaiters() {
        val context = setupTests("waiters-none.smithy", "com.test#TestHasNoWaiters")
        val filePaths = context.manifest.files
        filePaths.shouldNotContain(Path("/Test/Waiters.swift"))
    }

    private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
        val context =
            TestContext.initContextFrom(smithyFile, serviceShapeId, MockHttpRestJsonProtocolGenerator()) { model ->
                model.defaultSettings(serviceShapeId, "Test", "2019-12-16", "Test")
            }
        context.generator.generateProtocolClient(context.generationCtx)
        val unit = WaiterGenerator()
        val codegenContext = object : CodegenContext {
            override val model: Model = context.generationCtx.model
            override val symbolProvider: SymbolProvider = context.generationCtx.symbolProvider
            override val settings: SwiftSettings = context.generationCtx.settings
            override val protocolGenerator: ProtocolGenerator? = context.generator
            override val integrations: List<SwiftIntegration> = context.generationCtx.integrations
        }
        unit.writeAdditionalFiles(codegenContext, context.generationCtx, context.generationCtx.delegator)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
