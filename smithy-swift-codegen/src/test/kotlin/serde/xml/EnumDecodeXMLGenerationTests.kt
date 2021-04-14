package serde.xml

import MockHttpRestXMLProtocolGenerator
import TestContext
import defaultSettings
import getFileContents
import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test

class EnumDecodeXMLGenerationTests {

    @Test
    fun `decode enum`() {
        val context = setupTests("Isolated/Restxml/xml-enums.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlEnumsOutputBody+Decodable.swift")
        val expectedContents = """
        extension XmlEnumsOutputBody: Decodable {
            enum CodingKeys: String, CodingKey {
                case fooEnum1
                case fooEnum2
                case fooEnum3
                case fooEnumList
            }
        
            public init (from decoder: Decoder) throws {
                let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                let fooEnum1Decoded = try containerValues.decodeIfPresent(FooEnum.self, forKey: .fooEnum1)
                fooEnum1 = fooEnum1Decoded
                let fooEnum2Decoded = try containerValues.decodeIfPresent(FooEnum.self, forKey: .fooEnum2)
                fooEnum2 = fooEnum2Decoded
                let fooEnum3Decoded = try containerValues.decodeIfPresent(FooEnum.self, forKey: .fooEnum3)
                fooEnum3 = fooEnum3Decoded
                if containerValues.contains(.fooEnumList) {
                    struct KeyVal0{struct member{}}
                    let fooEnumListWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: CollectionMember<KeyVal0.member>.CodingKeys.self, forKey: .fooEnumList)
                    if let fooEnumListWrappedContainer = fooEnumListWrappedContainer {
                        let fooEnumListContainer = try fooEnumListWrappedContainer.decodeIfPresent([FooEnum].self, forKey: .member)
                        var fooEnumListBuffer:[FooEnum]? = nil
                        if let fooEnumListContainer = fooEnumListContainer {
                            fooEnumListBuffer = [FooEnum]()
                            for stringContainer0 in fooEnumListContainer {
                                fooEnumListBuffer?.append(stringContainer0)
                            }
                        }
                        fooEnumList = fooEnumListBuffer
                    } else {
                        fooEnumList = []
                    }
                } else {
                    fooEnumList = nil
                }
            }
        }
        """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `decode enum nested`() {
        val context = setupTests("Isolated/Restxml/xml-enums.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlEnumsNestedOutputBody+Decodable.swift")
        val expectedContents =
            """
            extension XmlEnumsNestedOutputBody: Decodable {
                enum CodingKeys: String, CodingKey {
                    case nestedEnumsList
                }
            
                public init (from decoder: Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    if containerValues.contains(.nestedEnumsList) {
                        struct KeyVal0{struct member{}}
                        let nestedEnumsListWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: CollectionMember<KeyVal0.member>.CodingKeys.self, forKey: .nestedEnumsList)
                        if let nestedEnumsListWrappedContainer = nestedEnumsListWrappedContainer {
                            let nestedEnumsListContainer = try nestedEnumsListWrappedContainer.decodeIfPresent([[FooEnum]?].self, forKey: .member)
                            var nestedEnumsListBuffer:[[FooEnum]?]? = nil
                            if let nestedEnumsListContainer = nestedEnumsListContainer {
                                nestedEnumsListBuffer = [[FooEnum]?]()
                                var listBuffer0: [FooEnum]? = nil
                                for listContainer0 in nestedEnumsListContainer {
                                    listBuffer0 = [FooEnum]()
                                    if let listContainer0 = listContainer0 {
                                        for stringContainer1 in listContainer0 {
                                            listBuffer0?.append(stringContainer1)
                                        }
                                    }
                                    nestedEnumsListBuffer?.append(listBuffer0)
                                }
                            }
                            nestedEnumsList = nestedEnumsListBuffer
                        } else {
                            nestedEnumsList = []
                        }
                    } else {
                        nestedEnumsList = nil
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
