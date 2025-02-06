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

class WaiterMethodGeneratorTests {
    @Test
    fun testRendersCorrectWaitersSwiftFileContentForServiceWithWaiters() {
        val context = setupTests("waiters.smithy", "com.test#TestHasWaiters")
        println(context.manifest.files)
        val contents = getFileContents(context.manifest, "/Sources/Test/Waiters.swift")
        val expected = """
/// Initiates waiting for the BucketExists event on the headBucket operation.
/// The operation will be tried and (if necessary) retried until the wait succeeds, fails, or times out.
/// Returns a `WaiterOutcome` asynchronously on waiter success, throws an error asynchronously on
/// waiter failure or timeout.
/// - Parameters:
///   - options: `WaiterOptions` to be used to configure this wait.
///   - input: The `HeadBucketInput` object to be used as a parameter when performing the operation.
/// - Returns: A `WaiterOutcome` with the result of the final, successful performance of the operation.
/// - Throws: `WaiterFailureError` if the waiter fails due to matching an `Acceptor` with state `failure`
/// or there is an error not handled by any `Acceptor.`
/// `WaiterTimeoutError` if the waiter times out.
public func waitUntilBucketExists(options: SmithyWaitersAPI.WaiterOptions, input: HeadBucketInput) async throws -> SmithyWaitersAPI.WaiterOutcome<HeadBucketOutput> {
    let waiter = SmithyWaitersAPI.Waiter(config: try Self.bucketExistsWaiterConfig(), operation: self.headBucket(input:))
    return try await waiter.waitUntil(options: options, input: input)
}
"""
        contents.shouldContainOnlyOnce(expected)
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
        val path = "/Sources/Test/Waiters.swift"
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
            val waiterName = waitableTrait.waiters.keys.first()
            val unit = WaiterMethodGenerator(writer, codegenContext, service, waitedOperation, waiterName)
            unit.render()
        }
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
