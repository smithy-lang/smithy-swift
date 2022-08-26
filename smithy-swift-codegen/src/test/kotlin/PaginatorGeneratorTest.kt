
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
        val contents = getFileContents(context.manifest, "/Test/Paginators.swift")
        val expected = """
       /// Paginate over `[ListFunctions2OutputResponse]` results.
       ///
       /// When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
       /// calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
       /// until then. If there are errors in your request, you will see the failures only after you start iterating.
       /// - Parameters:
       ///     - input: A `[ListFunctions2Input]` to start pagination
       /// - Returns: An `AsyncSequence` that can iterate over `ListFunctions2OutputResponse`
       extension TestClient {
           public func listFunctions2Paginated(input: ListFunctions2Input) -> ClientRuntime.PaginatorSequence<ListFunctions2Input, ListFunctions2OutputResponse> {
               return ClientRuntime.PaginatorSequence<ListFunctions2Input, ListFunctions2OutputResponse>(input: input, inputKey: \ListFunctions2Input.marker, outputKey: \ListFunctions2OutputResponse.nextMarker, paginationFunction: self.listFunctions2(input:))
           }
       }

       extension ListFunctions2Input: ClientRuntime.PaginateToken {
           public func usingPaginationToken(_ token: Swift.String) -> ListFunctions2Input {
               return ListFunctions2Input(
                   functionVersion: self.functionVersion,
                   marker: token,
                   masterRegion: self.masterRegion,
                   maxItems: self.maxItems
               )}
       }
        """.trimIndent()

        contents.shouldContainOnlyOnce(expected)
    }

    @Test
    fun testRenderPaginatorWithItem() {
        val context = setupTests("pagination.smithy", "com.test#Lambda")
        val contents = getFileContents(context.manifest, "/Test/Paginators.swift")
        val expectedCode = """
        /// Paginate over `[ListFunctionsOutputResponse]` results.
        ///
        /// When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
        /// calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
        /// until then. If there are errors in your request, you will see the failures only after you start iterating.
        /// - Parameters:
        ///     - input: A `[ListFunctionsInput]` to start pagination
        /// - Returns: An `AsyncSequence` that can iterate over `ListFunctionsOutputResponse`
        extension TestClient {
            public func listFunctionsPaginated(input: ListFunctionsInput) -> ClientRuntime.PaginatorSequence<ListFunctionsInput, ListFunctionsOutputResponse> {
                return ClientRuntime.PaginatorSequence<ListFunctionsInput, ListFunctionsOutputResponse>(input: input, inputKey: \ListFunctionsInput.marker, outputKey: \ListFunctionsOutputResponse.nextMarker, paginationFunction: self.listFunctions(input:))
            }
        }
        
        extension ListFunctionsInput: ClientRuntime.PaginateToken {
            public func usingPaginationToken(_ token: Swift.String) -> ListFunctionsInput {
                return ListFunctionsInput(
                    functionVersion: self.functionVersion,
                    marker: token,
                    masterRegion: self.masterRegion,
                    maxItems: self.maxItems
                )}
        }
        
        /// This paginator transforms the `AsyncSequence` returned by `listFunctionsPaginated`
        /// to access the nested member `[TestClientTypes.FunctionConfiguration]`
        /// - Returns: `[TestClientTypes.FunctionConfiguration]`
        extension PaginatorSequence where Input == ListFunctionsInput, Output == ListFunctionsOutputResponse {
            public func functions() async throws -> [TestClientTypes.FunctionConfiguration] {
                return try await self.asyncCompactMap { item in item.functions }
            }
        }
        """.trimIndent()

        contents.shouldContainOnlyOnce(expectedCode)
    }

    @Test
    fun testRenderPaginatorNoItemWithMapToken() {
        val context = setupTests("pagination-map.smithy", "com.test#TestService")
        val contents = getFileContents(context.manifest, "/Test/Paginators.swift")
        val expectedCode = """
        /// Paginate over `[PaginatedMapOutputResponse]` results.
        ///
        /// When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
        /// calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
        /// until then. If there are errors in your request, you will see the failures only after you start iterating.
        /// - Parameters:
        ///     - input: A `[PaginatedMapInput]` to start pagination
        /// - Returns: An `AsyncSequence` that can iterate over `PaginatedMapOutputResponse`
        extension TestClient {
            public func paginatedMapPaginated(input: PaginatedMapInput) -> ClientRuntime.PaginatorSequence<PaginatedMapInput, PaginatedMapOutputResponse> {
                return ClientRuntime.PaginatorSequence<PaginatedMapInput, PaginatedMapOutputResponse>(input: input, inputKey: \PaginatedMapInput.nextToken, outputKey: \PaginatedMapOutputResponse.inner?.token, paginationFunction: self.paginatedMap(input:))
            }
        }
        
        extension PaginatedMapInput: ClientRuntime.PaginateToken {
            public func usingPaginationToken(_ token: Swift.String) -> PaginatedMapInput {
                return PaginatedMapInput(
                    maxResults: self.maxResults,
                    nextToken: token
                )}
        }
        
        /// This paginator transforms the `AsyncSequence` returned by `paginatedMapPaginated`
        /// to access the nested member `[(String, Swift.Int)]`
        /// - Returns: `[(String, Swift.Int)]`
        extension PaginatorSequence where Input == PaginatedMapInput, Output == PaginatedMapOutputResponse {
            public func mapItems() async throws -> [(String, Swift.Int)] {
                return try await self.asyncCompactMap { item in item.inner?.mapItems?.map { (${'$'}0, ${'$'}1) } }
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
