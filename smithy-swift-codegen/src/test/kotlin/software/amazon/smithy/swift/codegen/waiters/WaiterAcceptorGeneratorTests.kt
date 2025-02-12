package software.amazon.smithy.swift.codegen.waiters

/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

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
import software.amazon.smithy.swift.codegen.TestContext
import software.amazon.smithy.swift.codegen.core.SwiftCodegenContext
import software.amazon.smithy.swift.codegen.defaultSettings
import software.amazon.smithy.swift.codegen.getFileContents
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.SwiftIntegration
import software.amazon.smithy.swift.codegen.model.expectShape
import software.amazon.smithy.swift.codegen.protocolgeneratormocks.MockHTTPRestJsonProtocolGenerator
import software.amazon.smithy.waiters.WaitableTrait

class WaiterAcceptorGeneratorTests {
    @Test
    fun `renders correct code for success acceptor`() {
        val context = setupTests("waiters.smithy", "com.test#TestHasWaiters", 0)
        val contents = getFileContents(context.manifest, "/Test/Waiters.swift")
        val expected = """
.init(state: .success, matcher: { (input: HeadBucketInput, result: Swift.Result<HeadBucketOutput, Swift.Error>) -> Bool in
    switch result {
        case .success: return true
        case .failure: return false
    }
}),
"""
        contents.shouldContainOnlyOnce(expected)
    }

    @Test
    fun `renders correct code for errorType acceptor`() {
        val context = setupTests("waiters.smithy", "com.test#TestHasWaiters", 1)
        val contents = getFileContents(context.manifest, "/Test/Waiters.swift")
        val expected = """
.init(state: .retry, matcher: { (input: HeadBucketInput, result: Swift.Result<HeadBucketOutput, Swift.Error>) -> Bool in
    guard case .failure(let error) = result else { return false }
    return (error as? ClientRuntime.ServiceError)?.typeName == "NotFound"
}),
"""
        contents.shouldContainOnlyOnce(expected)
    }

    @Test
    fun `renders correct code for output acceptor`() {
        val context = setupTests("waiters.smithy", "com.test#TestHasWaiters", 2)
        val contents = getFileContents(context.manifest, "/Test/Waiters.swift")
        val expected = """
.init(state: .success, matcher: { (input: HeadBucketInput, result: Swift.Result<HeadBucketOutput, Swift.Error>) -> Bool in
    // JMESPath expression: "field1"
    // JMESPath comparator: "stringEquals"
    // JMESPath expected value: "abc"
    guard case .success(let output) = result else { return false }
    let field1 = output.field1
    return SmithyWaitersAPI.JMESUtils.compare(field1, ==, "abc")
}),
"""
        contents.shouldContainOnlyOnce(expected)
    }

    @Test
    fun `renders correct code for inputOutput acceptor`() {
        val context = setupTests("waiters.smithy", "com.test#TestHasWaiters", 3)
        val contents = getFileContents(context.manifest, "/Test/Waiters.swift")
        val expected = """
.init(state: .success, matcher: { (input: HeadBucketInput, result: Swift.Result<HeadBucketOutput, Swift.Error>) -> Bool in
    // JMESPath expression: "input.bucketName == output.field1"
    // JMESPath comparator: "booleanEquals"
    // JMESPath expected value: "true"
    guard case .success(let unwrappedOutput) = result else { return false }
    let inputOutput = SmithyWaitersAPI.WaiterConfiguration<HeadBucketInput, HeadBucketOutput>.Acceptor.InputOutput(input: input, output: unwrappedOutput)
    let input = inputOutput.input
    let bucketName = input?.bucketName
    let output = inputOutput.output
    let field1 = output?.field1
    let comparison = SmithyWaitersAPI.JMESUtils.compare(bucketName, ==, field1)
    return SmithyWaitersAPI.JMESUtils.compare(comparison, ==, true)
}),
"""
        contents.shouldContainOnlyOnce(expected)
    }

    private fun setupTests(
        smithyFile: String,
        serviceShapeId: String,
        index: Int,
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
                override val protocolGenerator: ProtocolGenerator = context.generator
                override val integrations: List<SwiftIntegration> = context.generationCtx.integrations

                override fun model(): Model = model

                override fun settings(): SwiftSettings = settings

                override fun symbolProvider(): SymbolProvider = symbolProvider

                override fun fileManifest(): FileManifest = fileManifest

                override fun writerDelegator(): WriterDelegator<SwiftWriter> =
                    SwiftDelegator(settings, model, fileManifest, symbolProvider, integrations)

                override fun integrations(): MutableList<SwiftIntegration> = integrations.toMutableList()
            }
        val path = "Test/Waiters.swift"
        context.generationCtx.delegator.useFileWriter(path) { writer ->
            val service = codegenContext.model.expectShape<ServiceShape>(codegenContext.settings.service)
            val waitedOperation =
                service.allOperations
                    .map { codegenContext.model.expectShape<OperationShape>(it) }
                    .first()
            val waitableTrait =
                waitedOperation.allTraits.values
                    .mapNotNull { it as? WaitableTrait }
                    .first()
            val waiter = waitableTrait.waiters.values.first()
            val acceptor = waiter.acceptors[index]
            val unit = WaiterAcceptorGenerator(writer, codegenContext, service, waitedOperation, acceptor)
            unit.render()
        }
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
