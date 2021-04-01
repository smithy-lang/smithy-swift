package serde.xml

import MockHttpRestXMLProtocolGenerator
import TestContext
import defaultSettings
import getFileContents
import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test

class RecursiveShapesEncodeXMLGenerationTests {
    @Test
    fun `encode recursive shape Nested1`() {
        val context = setupTests("Isolated/Restxml/xml-recursive.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/RecursiveShapesInputOutputNested1+Codable.swift")
        val expectedContents =
            """
            extension RecursiveShapesInputOutputNested1: Codable, Reflection {
                private enum CodingKeys: String, CodingKey {
                    case foo
                    case nested
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    if let foo = foo {
                        try container.encode(foo, forKey: .foo)
                    }
                    if let nested = nested {
                        try container.encode(nested, forKey: .nested)
                    }
                }
            
                public init (from decoder: Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    let fooDecoded = try containerValues.decodeIfPresent(String.self, forKey: .foo)
                    foo = fooDecoded
                    let nestedDecoded = try containerValues.decodeIfPresent(Box<RecursiveShapesInputOutputNested2>.self, forKey: .nested)
                    nested = nestedDecoded
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `encode recursive shape Nested2`() {
        val context = setupTests("Isolated/Restxml/xml-recursive.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/RecursiveShapesInputOutputNested2+Codable.swift")
        val expectedContents =
            """
            extension RecursiveShapesInputOutputNested2: Codable, Reflection {
                private enum CodingKeys: String, CodingKey {
                    case bar
                    case recursiveMember
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    if let bar = bar {
                        try container.encode(bar, forKey: .bar)
                    }
                    if let recursiveMember = recursiveMember {
                        try container.encode(recursiveMember, forKey: .recursiveMember)
                    }
                }
            
                public init (from decoder: Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    let barDecoded = try containerValues.decodeIfPresent(String.self, forKey: .bar)
                    bar = barDecoded
                    let recursiveMemberDecoded = try containerValues.decodeIfPresent(RecursiveShapesInputOutputNested1.self, forKey: .recursiveMember)
                    recursiveMember = recursiveMemberDecoded
                }
            }
            """.trimIndent()

        contents.shouldContainOnlyOnce(expectedContents)
    }
    @Test
    fun `encode recursive nested shape`() {
        val context = setupTests("Isolated/Restxml/xml-recursive-nested.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlNestedRecursiveShapesInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlNestedRecursiveShapesInput: Encodable, Reflection {
                private enum CodingKeys: String, CodingKey {
                    case nestedRecursiveList
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    if let nestedRecursiveList = nestedRecursiveList {
                        var nestedRecursiveListContainer = container.nestedContainer(keyedBy: Key.self, forKey: .nestedRecursiveList)
                        for nestedrecursiveshapeslist0 in nestedRecursiveList {
                            if let nestedrecursiveshapeslist0 = nestedrecursiveshapeslist0 {
                                var nestedrecursiveshapeslist0Container0 = nestedRecursiveListContainer.nestedContainer(keyedBy: Key.self, forKey: Key("member"))
                                for recursiveshapesinputoutputnested11 in nestedrecursiveshapeslist0 {
                                    try nestedrecursiveshapeslist0Container0.encode(recursiveshapesinputoutputnested11, forKey: Key("member"))
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
        context.generator.generateSerializers(context.generationCtx)
        context.generator.generateCodableConformanceForNestedTypes(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
