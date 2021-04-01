package serde.xml

import MockHttpRestXMLProtocolGenerator
import TestContext
import defaultSettings
import getFileContents
import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test

class SetDecodeXMLGenerationTests {
    @Test
    fun `XmlEnumSetOutputBody decodable`() {
        val context = setupTests("Isolated/Restxml/xml-sets.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlEnumSetOutputBody+Decodable.swift")
        val expectedContents =
            """
            extension XmlEnumSetOutputBody: Decodable {
                private enum CodingKeys: String, CodingKey {
                    case fooEnumSet
                }
            
                public init (from decoder: Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    if containerValues.contains(.fooEnumSet) {
                        struct KeyVal0{struct member{}}
                        let fooEnumSetWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: CollectionMember<KeyVal0.member>.CodingKeys.self, forKey: .fooEnumSet)
                        if let fooEnumSetWrappedContainer = fooEnumSetWrappedContainer {
                            let fooEnumSetContainer = try fooEnumSetWrappedContainer.decodeIfPresent([FooEnum].self, forKey: .member)
                            var fooEnumSetBuffer:Set<FooEnum>? = nil
                            if let fooEnumSetContainer = fooEnumSetContainer {
                                fooEnumSetBuffer = Set<FooEnum>()
                                for stringContainer0 in fooEnumSetContainer {
                                    fooEnumSetBuffer?.insert(stringContainer0)
                                }
                            }
                            fooEnumSet = fooEnumSetBuffer
                        } else {
                            fooEnumSet = []
                        }
                    } else {
                        fooEnumSet = nil
                    }
                }
            }
            """.trimIndent()

        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `XmlEnumNestedSetOutputBody nested decodable`() {
        val context = setupTests("Isolated/Restxml/xml-sets-nested.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlEnumNestedSetOutputBody+Decodable.swift")
        val expectedContents =
            """
            extension XmlEnumNestedSetOutputBody: Decodable {
                private enum CodingKeys: String, CodingKey {
                    case fooEnumSet
                }
            
                public init (from decoder: Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    if containerValues.contains(.fooEnumSet) {
                        struct KeyVal0{struct member{}}
                        let fooEnumSetWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: CollectionMember<KeyVal0.member>.CodingKeys.self, forKey: .fooEnumSet)
                        if let fooEnumSetWrappedContainer = fooEnumSetWrappedContainer {
                            let fooEnumSetContainer = try fooEnumSetWrappedContainer.decodeIfPresent([[FooEnum]].self, forKey: .member)
                            var fooEnumSetBuffer:Set<Set<FooEnum>>? = nil
                            if let fooEnumSetContainer = fooEnumSetContainer {
                                fooEnumSetBuffer = Set<Set<FooEnum>>()
                                for setContainer0 in fooEnumSetContainer {
                                    var setBuffer0 = Set<FooEnum>()
                                    for stringContainer1 in setContainer0 {
                                        setBuffer0.insert(stringContainer1)
                                    }
                                    fooEnumSetBuffer?.insert(setBuffer0)
                                }
                            }
                            fooEnumSet = fooEnumSetBuffer
                        } else {
                            fooEnumSet = []
                        }
                    } else {
                        fooEnumSet = nil
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
