/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package serde.xml

import MockHttpRestXMLProtocolGenerator
import TestContext
import defaultSettings
import getFileContents
import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test

class RecursiveShapesEncodeXMLGenerationTests {
    @Test
    fun `001 encode recursive shape Nested1`() {
        val context = setupTests("Isolated/Restxml/xml-recursive.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/RecursiveShapesInputOutputNested1+Codable.swift")
        val expectedContents =
            """
            extension RestXmlProtocolClientTypes.RecursiveShapesInputOutputNested1: Swift.Codable, Runtime.Reflection {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case foo
                    case nested
                }
            
                public func encode(to encoder: Swift.Encoder) throws {
                    var container = encoder.container(keyedBy: Runtime.Key.self)
                    if let foo = foo {
                        try container.encode(foo, forKey: Runtime.Key("foo"))
                    }
                    if let nested = nested {
                        try container.encode(nested, forKey: Runtime.Key("nested"))
                    }
                }
            
                public init (from decoder: Swift.Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    let fooDecoded = try containerValues.decodeIfPresent(Swift.String.self, forKey: .foo)
                    foo = fooDecoded
                    let nestedDecoded = try containerValues.decodeIfPresent(Box<RestXmlProtocolClientTypes.RecursiveShapesInputOutputNested2>.self, forKey: .nested)
                    nested = nestedDecoded
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `encode recursive shape Nested2`() {
        val context = setupTests("Isolated/Restxml/xml-recursive.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/RecursiveShapesInputOutputNested2+Codable.swift")
        val expectedContents =
            """
            extension RestXmlProtocolClientTypes.RecursiveShapesInputOutputNested2: Swift.Codable, Runtime.Reflection {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case bar
                    case recursiveMember
                }
            
                public func encode(to encoder: Swift.Encoder) throws {
                    var container = encoder.container(keyedBy: Runtime.Key.self)
                    if let bar = bar {
                        try container.encode(bar, forKey: Runtime.Key("bar"))
                    }
                    if let recursiveMember = recursiveMember {
                        try container.encode(recursiveMember, forKey: Runtime.Key("recursiveMember"))
                    }
                }
            
                public init (from decoder: Swift.Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    let barDecoded = try containerValues.decodeIfPresent(Swift.String.self, forKey: .bar)
                    bar = barDecoded
                    let recursiveMemberDecoded = try containerValues.decodeIfPresent(RestXmlProtocolClientTypes.RecursiveShapesInputOutputNested1.self, forKey: .recursiveMember)
                    recursiveMember = recursiveMemberDecoded
                }
            }
            """.trimIndent()

        contents.shouldContainOnlyOnce(expectedContents)
    }
    @Test
    fun `encode recursive nested shape`() {
        val context = setupTests("Isolated/Restxml/xml-recursive-nested.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlNestedRecursiveShapesInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlNestedRecursiveShapesInput: Swift.Encodable, Runtime.Reflection {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case nestedRecursiveList
                }
            
                public func encode(to encoder: Swift.Encoder) throws {
                    var container = encoder.container(keyedBy: Runtime.Key.self)
                    if let nestedRecursiveList = nestedRecursiveList {
                        var nestedRecursiveListContainer = container.nestedContainer(keyedBy: Runtime.Key.self, forKey: Runtime.Key("nestedRecursiveList"))
                        for nestedrecursiveshapeslist0 in nestedRecursiveList {
                            var nestedrecursiveshapeslist0Container0 = nestedRecursiveListContainer.nestedContainer(keyedBy: Runtime.Key.self, forKey: Runtime.Key("member"))
                            for recursiveshapesinputoutputnested11 in nestedrecursiveshapeslist0 {
                                try nestedrecursiveshapeslist0Container0.encode(recursiveshapesinputoutputnested11, forKey: Runtime.Key("member"))
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
