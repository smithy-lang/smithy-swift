package serde.awsjson11

import TestContext
import defaultSettings
import getFileContents
import io.kotest.matchers.string.shouldContainOnlyOnce
import mocks.MockHttpAWSJson11ProtocolGenerator
import org.junit.jupiter.api.Test
import shouldSyntacticSanityCheck

class NestedListEncodeJSONGenerationTests {

    @Test
    fun `list of maps of lists`() {
        val context = setupTests("Isolated/json11/list-of-maps-of-lists.smithy", "aws.protocoltests.json#JsonProtocol")
        val contents = getFileContents(context.manifest, "/Example/models/ListOfMapsOperationInput.swift")
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            public struct ListOfMapsOperationInput: Equatable {
                public let targetMaps: [[String:[String]?]?]?

                public init (
                    targetMaps: [[String:[String]?]?]? = nil
                )
                {
                    self.targetMaps = targetMaps
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }
    private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
        val context = TestContext.initContextFrom(smithyFile, serviceShapeId, MockHttpAWSJson11ProtocolGenerator()) { model ->
            model.defaultSettings(serviceShapeId, "Example", "2014-11-06", "aws json 11")
        }
        context.generator.generateCodableConformanceForNestedTypes(context.generationCtx)
        context.generator.generateSerializers(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}