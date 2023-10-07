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
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.ServiceShape
import software.amazon.smithy.swift.codegen.SwiftSettings
import software.amazon.smithy.swift.codegen.core.CodegenContext
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.SwiftIntegration
import software.amazon.smithy.swift.codegen.model.expectShape
import software.amazon.smithy.swift.codegen.waiters.WaiterAcceptorGenerator
import software.amazon.smithy.waiters.WaitableTrait

class WaiterAcceptorGeneratorTests {

    @Test
    fun `renders correct code for success acceptor`() {
        val context = setupTests("waiters.smithy", "com.test#TestHasWaiters", 0)
        val contents = getFileContents(context.manifest, "/Test/Waiters.swift")
        val expected = """
            .init(state: .success, matcher: { (input: HeadBucketInput, result: Result<HeadBucketOutput, Error>) -> Bool in
                switch result {
                    case .success: return true
                    case .failure: return false
                }
            }),
        """.trimIndent()
        contents.shouldContainOnlyOnce(expected)
    }

    @Test
    fun `renders correct code for errorType acceptor`() {
        val context = setupTests("waiters.smithy", "com.test#TestHasWaiters", 1)
        val contents = getFileContents(context.manifest, "/Test/Waiters.swift")
        val expected = """
            .init(state: .retry, matcher: { (input: HeadBucketInput, result: Result<HeadBucketOutput, Error>) -> Bool in
                guard case .failure(let error) = result else { return false }
                return (error as? ServiceError)?.typeName == "NotFound"
            }),
        """.trimIndent()
        contents.shouldContainOnlyOnce(expected)
    }

    @Test
    fun `renders correct code for output acceptor`() {
        val context = setupTests("waiters.smithy", "com.test#TestHasWaiters", 2)
        val contents = getFileContents(context.manifest, "/Test/Waiters.swift")
        val expected = """
            .init(state: .success, matcher: { (input: HeadBucketInput, result: Result<HeadBucketOutput, Error>) -> Bool in
                // JMESPath expression: "field1"
                // JMESPath comparator: "stringEquals"
                // JMESPath expected value: "abc"
                guard case .success(let output) = result else { return false }
                let field1 = output.field1
                return JMESUtils.compare(field1, ==, "abc")
            }),
        """.trimIndent()
        contents.shouldContainOnlyOnce(expected)
    }

    @Test
    fun `renders correct code for inputOutput acceptor`() {
        val context = setupTests("waiters.smithy", "com.test#TestHasWaiters", 3)
        val contents = getFileContents(context.manifest, "/Test/Waiters.swift")
        val expected = """
            .init(state: .success, matcher: { (input: HeadBucketInput, result: Result<HeadBucketOutput, Error>) -> Bool in
                // JMESPath expression: "input.bucketName == output.field1"
                // JMESPath comparator: "booleanEquals"
                // JMESPath expected value: "true"
                guard case .success(let unwrappedOutput) = result else { return false }
                let inputOutput = WaiterConfiguration<HeadBucketInput, HeadBucketOutput>.Acceptor.InputOutput(input: input, output: unwrappedOutput)
                let input = inputOutput.input
                let bucketName = input?.bucketName
                let output = inputOutput.output
                let field1 = output?.field1
                let comparison = JMESUtils.compare(bucketName, ==, field1)
                return JMESUtils.compare(comparison, ==, true)
            }),
        """.trimIndent()
        contents.shouldContainOnlyOnce(expected)
    }

    private fun setupTests(smithyFile: String, serviceShapeId: String, index: Int): TestContext {
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
            val service = codegenContext.model.expectShape<ServiceShape>(codegenContext.settings.service)
            val waitedOperation = service.allOperations
                .map { codegenContext.model.expectShape<OperationShape>(it) }.first()
            val waitableTrait = waitedOperation.allTraits.values.mapNotNull { it as? WaitableTrait }.first()
            val waiter = waitableTrait.waiters.values.first()
            val acceptor = waiter.acceptors[index]
            val unit = WaiterAcceptorGenerator(writer, codegenContext, service, waitedOperation, acceptor)
            unit.render()
        }
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
