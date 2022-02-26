
import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.swift.codegen.PaginatorGenerator
import software.amazon.smithy.swift.codegen.SwiftSettings
import software.amazon.smithy.swift.codegen.core.CodegenContext
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.SwiftIntegration

class PaginatorGeneratorTest {
    @Test
    fun testRenderPaginatorNoItem() {
        val context = setupTests("pagination.smithy", "com.test#Lambda")
        val contents = getFileContents(context.manifest, "/Test/Pagination.swift")
        val expected = """
            /**
             * Paginate over [ListFunctionsResponse] results.
             * When this operation is called, a [kotlinx.coroutines.Flow] is created. Flows are lazy (cold) so no service calls are
             * made until the flow is collected. This also means there is no guarantee that the request is valid until then. Once
             * you start collecting the flow, the SDK will lazily load response pages by making service calls until there are no
             * pages left or the flow is cancelled. If there are errors in your request, you will see the failures only after you start
             * collection.
             * @param initialRequest A [ListFunctionsRequest] to start pagination
             * @return A [kotlinx.coroutines.flow.Flow] that can collect [ListFunctionsResponse]
             */
            fun TestClient.listFunctionsPaginated(initialRequest: ListFunctionsRequest): Flow<ListFunctionsResponse> =
                flow {
                    var cursor: String? = null
                    var isFirstPage: Boolean = true
            
                    while (isFirstPage || (cursor?.isNotEmpty() == true)) {
                        val req = initialRequest.copy {
                            this.marker = cursor
                        }
                        val result = this@listFunctionsPaginated.listFunctions(req)
                        isFirstPage = false
                        cursor = result.nextMarker
                        emit(result)
                    }
                }
        """.trimIndent()

        contents.shouldContainOnlyOnce(expected)
    }

    @Test
    fun testRenderPaginatorWithItem() {
        val context = setupTests("pagination.smithy", "com.test#Lambda")
        val contents = getFileContents(context.manifest, "/Test/Pagination.swift")
        val expectedCode = """
            /**
             * Paginate over [ListFunctionsResponse] results.
             * When this operation is called, a [kotlinx.coroutines.Flow] is created. Flows are lazy (cold) so no service calls are
             * made until the flow is collected. This also means there is no guarantee that the request is valid until then. Once
             * you start collecting the flow, the SDK will lazily load response pages by making service calls until there are no
             * pages left or the flow is cancelled. If there are errors in your request, you will see the failures only after you start
             * collection.
             * @param initialRequest A [ListFunctionsRequest] to start pagination
             * @return A [kotlinx.coroutines.flow.Flow] that can collect [ListFunctionsResponse]
             */
            fun TestClient.listFunctionsPaginated(initialRequest: ListFunctionsRequest): Flow<ListFunctionsResponse> =
                flow {
                    var cursor: String? = null
                    var isFirstPage: Boolean = true
            
                    while (isFirstPage || (cursor?.isNotEmpty() == true)) {
                        val req = initialRequest.copy {
                            this.marker = cursor
                        }
                        val result = this@listFunctionsPaginated.listFunctions(req)
                        isFirstPage = false
                        cursor = result.nextMarker
                        emit(result)
                    }
                }
            
            /**
             * This paginator transforms the flow returned by [listFunctionsPaginated]
             * to access the nested member [FunctionConfiguration]
             * @return A [kotlinx.coroutines.flow.Flow] that can collect [FunctionConfiguration]
             */
            @JvmName("listFunctionsResponseFunctionConfiguration")
            fun Flow<ListFunctionsResponse>.functions(): Flow<FunctionConfiguration> =
                transform() { response ->
                    response.functions?.forEach {
                        emit(it)
                    }
                }
        """.trimIndent()

        contents.shouldContainOnlyOnce(expectedCode)
    }

    private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
        val context = TestContext.initContextFrom(smithyFile, serviceShapeId, MockHttpRestJsonProtocolGenerator()) { model ->
            model.defaultSettings(serviceShapeId, "Test", "2019-12-16", "Test")
        }
        context.generator.generateProtocolClient(context.generationCtx)
        val unit = PaginatorGenerator()
        val codegenContext = object : CodegenContext {
            override val model: Model = context.generationCtx.model
            override val symbolProvider: SymbolProvider = context.generationCtx.symbolProvider
            override val settings: SwiftSettings = context.generationCtx.settings
            override val protocolGenerator: ProtocolGenerator? = context.generator
            override val integrations: List<SwiftIntegration> = context.generationCtx.integrations
        }
        unit.writeAdditionalFiles(codegenContext, context.generationCtx.delegator)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}