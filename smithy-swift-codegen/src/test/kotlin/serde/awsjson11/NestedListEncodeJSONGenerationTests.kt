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

    @Test
    fun `encode list of maps of lists`() {
        val context = setupTests("Isolated/json11/list-of-maps-of-lists.smithy", "aws.protocoltests.json#JsonProtocol")
        val contents = getFileContents(context.manifest, "/Example/models/ListOfMapsOperationInput+Encodable.swift")
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            extension ListOfMapsOperationInput: Encodable, Reflection {
                enum CodingKeys: String, CodingKey {
                    case targetMaps
                }
            
                public func encode(to encoder: Encoder) throws {
                    var encodeContainer = encoder.container(keyedBy: CodingKeys.self)
                    if let targetMaps = targetMaps {
                        var targetMapsContainer = encodeContainer.nestedUnkeyedContainer(forKey: .targetMaps)
                        for targetmaps0 in targetMaps {
                        //THIS IS BROKEN:
                            var targetmaps0Container = targetMapsContainer.nestedContainer(keyedBy: Key.self)
                            if let targetmaps0 = targetmaps0 {
                                for (dictKey1, targetmap1) in targetmaps0 {
                                //THIS IS BROKEN
                                    var targetmap1Container = targetmaps0Container.nestedContainer(keyedBy: Key.self)
                                    for (dictKey2, targetmapvaluelist2) in targetmap1 {
                                        try targetmap1Container.encode(targetmapvaluelist2, forKey: Key(stringValue: dictKey2))
                                    }
                                }
                            }
                        }
                    }
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