package serde.xml

import MockHttpRestXMLProtocolGenerator
import TestContext
import defaultSettings
import getFileContents
import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test

class ListEncodeXMLGenerationTests {
    @Test
    fun `001 wrapped list with xmlName`() {
        val context = setupTests("Isolated/Restxml/xml-lists-xmlname.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlListXmlNameInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlListXmlNameInput: Encodable, Reflection {
                private enum CodingKeys: String, CodingKey {
                    case renamedListMembers = "renamed"
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    if let renamedListMembers = renamedListMembers {
                        var renamedListMembersContainer = container.nestedContainer(keyedBy: Key.self, forKey: .renamedListMembers)
                        for string0 in renamedListMembers {
                            try renamedListMembersContainer.encode(string0, forKey: Key("item"))
                        }
                    }
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `002 nested wrapped list with xmlname`() {
        val context = setupTests("Isolated/Restxml/xml-lists-xmlname-nested.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlListXmlNameNestedInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlListXmlNameNestedInput: Encodable, Reflection {
                private enum CodingKeys: String, CodingKey {
                    case renamedListMembers = "renamed"
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    if let renamedListMembers = renamedListMembers {
                        var renamedListMembersContainer = container.nestedContainer(keyedBy: Key.self, forKey: .renamedListMembers)
                        for renamedlistmembers0 in renamedListMembers {
                            if let renamedlistmembers0 = renamedlistmembers0 {
                                var renamedlistmembers0Container0 = renamedListMembersContainer.nestedContainer(keyedBy: Key.self, forKey: Key("item"))
                                for string1 in renamedlistmembers0 {
                                    try renamedlistmembers0Container0.encode(string1, forKey: Key("subItem"))
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
        val context = TestContext.initContextFrom(smithyFile, serviceShapeId, MockHttpRestXMLProtocolGenerator()) { model ->
            model.defaultSettings(serviceShapeId, "RestXml", "2019-12-16", "Rest Xml Protocol")
        }
        context.generator.generateCodableConformanceForNestedTypes(context.generationCtx)
        context.generator.generateSerializers(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
