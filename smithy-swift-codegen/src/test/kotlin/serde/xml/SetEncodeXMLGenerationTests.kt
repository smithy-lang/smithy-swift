package serde.xml

import MockHttpRestXMLProtocolGenerator
import TestContext
import defaultSettings
import getFileContents
import io.kotest.matchers.string.shouldContainOnlyOnce
import listFilesFromManifest
import org.junit.jupiter.api.Test

class SetEncodeXMLGenerationTests {
    @Test
    fun `wrapped set serialization`() {
        val context = setupTests("Isolated/Restxml/xml-sets.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlEnumSetInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlEnumSetInput: Encodable, Reflection {
                private enum CodingKeys: String, CodingKey {
                    case fooEnumSet
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    if let fooEnumSet = fooEnumSet {
                        var fooEnumSetContainer = container.nestedContainer(keyedBy: WrappedListMember.CodingKeys.self, forKey: .fooEnumSet)
                        for fooenum0 in fooEnumSet {
                            try fooEnumSetContainer.encode(fooenum0, forKey: .member)
                        }
                    }
                }
            }
            """.trimIndent()

        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `wrapped nested set serialization`() {
        val context = setupTests("Isolated/Restxml/xml-sets-nested.smithy", "aws.protocoltests.restxml#RestXml")
        print(listFilesFromManifest(context.manifest))
        val contents = getFileContents(context.manifest, "/example/models/XmlEnumNestedSetInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlEnumNestedSetInput: Encodable, Reflection {
                private enum CodingKeys: String, CodingKey {
                    case fooEnumSet
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    if let fooEnumSet = fooEnumSet {
                        var fooEnumSetContainer = container.nestedContainer(keyedBy: WrappedListMember.CodingKeys.self, forKey: .fooEnumSet)
                        for fooenumset0 in fooEnumSet {
                            var fooenumset0Container0 = fooEnumSetContainer.nestedContainer(keyedBy: WrappedListMember.CodingKeys.self, forKey: .member)
                            for fooenum1 in fooenumset0 {
                                try fooenumset0Container0.encode(fooenum1, forKey: .member)
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
