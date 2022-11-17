import io.kotest.matchers.booleans.shouldBeFalse
import io.kotest.matchers.booleans.shouldBeTrue
import io.kotest.matchers.collections.shouldContain
import io.kotest.matchers.collections.shouldNotContain
import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.swift.codegen.SwiftSettings
import software.amazon.smithy.swift.codegen.WaiterGenerator
import software.amazon.smithy.swift.codegen.core.CodegenContext
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.SwiftIntegration
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

    @Test
    fun testRendersCorrectWaitersSwiftFileContentForServiceWithWaiters() {
        val context = setupTests("waiters.smithy", "com.test#TestHasWaiters")
        val contents = getFileContents(context.manifest, "/Test/Waiters.swift")
        val expected = """
            extension TestClientProtocol {

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
                public func waitUntilBucketExists(options: WaiterOptions, input: HeadBucketInput) async throws -> WaiterOutcome<HeadBucketOutputResponse> {
                    let acceptors: [WaiterConfiguration<HeadBucketInput, HeadBucketOutputResponse>.Acceptor] = []  // acceptors will be filled in a future PR
                    let config = try WaiterConfiguration(acceptors: acceptors, minDelay: 7.0, maxDelay: 22.0)
                    let waiter = Waiter(config: config, operation: self.headBucket(input:))
                    return try await waiter.waitUntil(options: options, input: input)
                }
            }
        """.trimIndent()
        contents.shouldContainOnlyOnce(expected)
    }

    private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
        val context = TestContext.initContextFrom(smithyFile, serviceShapeId, MockHttpRestJsonProtocolGenerator()) { model ->
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
