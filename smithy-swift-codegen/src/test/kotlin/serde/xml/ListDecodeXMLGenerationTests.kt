package serde.xml

import MockHttpRestXMLProtocolGenerator
import TestContext
import defaultSettings
import getFileContents
import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test

class ListDecodeXMLGenerationTests {
    @Test
    fun `001 wrapped list with xmlName`() {
        val context = setupTests("Isolated/Restxml/xml-lists-xmlname.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlListXmlNameOutputBody+Decodable.swift")
        val expectedContents =
            """
            extension XmlListXmlNameOutputBody: Decodable {
                enum CodingKeys: String, CodingKey {
                    case renamedListMembers = "renamed"
                }
            
                public init (from decoder: Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    if containerValues.contains(.renamedListMembers) {
                        struct KeyVal0{struct item{}}
                        let renamedListMembersWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: CollectionMember<KeyVal0.item>.CodingKeys.self, forKey: .renamedListMembers)
                        if let renamedListMembersWrappedContainer = renamedListMembersWrappedContainer {
                            let renamedListMembersContainer = try renamedListMembersWrappedContainer.decodeIfPresent([String].self, forKey: .member)
                            var renamedListMembersBuffer:[String]? = nil
                            if let renamedListMembersContainer = renamedListMembersContainer {
                                renamedListMembersBuffer = [String]()
                                for stringContainer0 in renamedListMembersContainer {
                                    renamedListMembersBuffer?.append(stringContainer0)
                                }
                            }
                            renamedListMembers = renamedListMembersBuffer
                        } else {
                            renamedListMembers = []
                        }
                    } else {
                        renamedListMembers = nil
                    }
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `002 wrapped nested list with xmlname`() {
        val context = setupTests("Isolated/Restxml/xml-lists-xmlname-nested.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlListXmlNameNestedOutputBody+Decodable.swift")
        val expectedContents = """
        extension XmlListXmlNameNestedOutputBody: Decodable {
            enum CodingKeys: String, CodingKey {
                case renamedListMembers = "renamed"
            }
        
            public init (from decoder: Decoder) throws {
                let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                if containerValues.contains(.renamedListMembers) {
                    struct KeyVal0{struct item{}}
                    let renamedListMembersWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: CollectionMember<KeyVal0.item>.CodingKeys.self, forKey: .renamedListMembers)
                    if let renamedListMembersWrappedContainer = renamedListMembersWrappedContainer {
                        let renamedListMembersContainer = try renamedListMembersWrappedContainer.decodeIfPresent([[String]?].self, forKey: .member)
                        var renamedListMembersBuffer:[[String]?]? = nil
                        if let renamedListMembersContainer = renamedListMembersContainer {
                            renamedListMembersBuffer = [[String]?]()
                            for listContainer0 in renamedListMembersContainer {
                                var listBuffer0 = [String]()
                                if let listContainer0 = listContainer0 {
                                    for stringContainer1 in listContainer0 {
                                        listBuffer0.append(stringContainer1)
                                    }
                                }
                                renamedListMembersBuffer?.append(listBuffer0)
                            }
                        }
                        renamedListMembers = renamedListMembersBuffer
                    } else {
                        renamedListMembers = []
                    }
                } else {
                    renamedListMembers = nil
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
        context.generator.generateDeserializers(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
