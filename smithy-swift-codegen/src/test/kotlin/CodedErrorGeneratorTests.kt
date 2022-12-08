import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test
import software.amazon.smithy.swift.codegen.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.integration.httpResponse.CodedErrorGenerator

class CodedErrorGeneratorTests {

    @Test
    fun `renders correct CodedError extension for operation error`() {
        val context = setupTests("coded-error.smithy", "com.test#CodedErrorTest")
        val contents = getFileContents(context.manifest, "/CodedErrorTest/models/GetWidgetOutputError+CodedError.swift")
        val expected = """
        extension GetWidgetOutputError: CodedError {
        
            /// The error code for this error, or `nil` if the code could not be determined.
            /// How this code is determined depends on the protocol used to decode the error response.
            public var errorCode: String? {
                switch self {
                case .invalidWidgetError: return "InvalidWidgetError"
                case .widgetNotFoundError: return "WidgetNotFoundError"
                case .unknown(let error): return error.errorCode
                }
            }
        }
        """.trimIndent()
        contents.shouldContainOnlyOnce(expected)
    }

    private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
        val context = TestContext.initContextFrom(smithyFile, serviceShapeId, MockHttpRestJsonProtocolGenerator()) { model ->
            model.defaultSettings(serviceShapeId, "CodedErrorTest", "2019-12-16", "CodedErrorTest")
        }
        context.generator.generateProtocolClient(context.generationCtx)
        val operationShape = context.generationCtx.model.operationShapes.first()
        CodedErrorGenerator(context.generationCtx, operationShape, ClientRuntimeTypes.Http.UnknownHttpServiceError).render()
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
