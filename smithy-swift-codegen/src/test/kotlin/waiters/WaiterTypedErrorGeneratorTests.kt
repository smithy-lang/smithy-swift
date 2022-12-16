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
import software.amazon.smithy.swift.codegen.waiters.WaiterTypedErrorGenerator

class WaiterTypedErrorGeneratorTests {

    @Test
    fun `renders correct WaiterTypedError extension for operation error`() {
        val context = setupTests("waiter-typed-error.smithy", "com.test#WaiterTypedErrorTest")
        val contents = getFileContents(
            context.manifest,
            "/WaiterTypedErrorTest/models/GetWidgetOutputError+WaiterTypedError.swift"
        )
        val expected = """
        extension GetWidgetOutputError: WaiterTypedError {
        
            /// The Smithy identifier, without namespace, for the type of this error, or `nil` if the
            /// error has no known type.
            public var waiterErrorType: String? {
                switch self {
                case .invalidWidgetError: return "InvalidWidgetError"
                case .widgetNotFoundError: return "WidgetNotFoundError"
                case .unknown(let error): return error.waiterErrorType
                }
            }
        }
        """.trimIndent()
        contents.shouldContainOnlyOnce(expected)
    }

    private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
        val context =
            TestContext.initContextFrom(smithyFile, serviceShapeId, MockHttpRestJsonProtocolGenerator()) { model ->
                model.defaultSettings(serviceShapeId, "WaiterTypedErrorTest", "2019-12-16", "WaiterTypedErrorTest")
            }
        context.generator.generateProtocolClient(context.generationCtx)
        val operationShape = context.generationCtx.model.operationShapes.first()
        WaiterTypedErrorGenerator(context.generationCtx, operationShape).render()
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
