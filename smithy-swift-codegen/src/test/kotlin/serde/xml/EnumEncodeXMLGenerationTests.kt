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

class EnumEncodeXMLGenerationTests {
    @Test
    fun `001 encode enum`() {
        val context = setupTests("Isolated/Restxml/xml-enums.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlEnumsInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlEnumsInput: Swift.Encodable, Runtime.Reflection {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case fooEnum1
                    case fooEnum2
                    case fooEnum3
                    case fooEnumList
                }
            
                public func encode(to encoder: Swift.Encoder) throws {
                    var container = encoder.container(keyedBy: Runtime.Key.self)
                    if let fooEnum1 = fooEnum1 {
                        try container.encode(fooEnum1, forKey: Runtime.Key("fooEnum1"))
                    }
                    if let fooEnum2 = fooEnum2 {
                        try container.encode(fooEnum2, forKey: Runtime.Key("fooEnum2"))
                    }
                    if let fooEnum3 = fooEnum3 {
                        try container.encode(fooEnum3, forKey: Runtime.Key("fooEnum3"))
                    }
                    if let fooEnumList = fooEnumList {
                        var fooEnumListContainer = container.nestedContainer(keyedBy: Runtime.Key.self, forKey: Runtime.Key("fooEnumList"))
                        for fooenum0 in fooEnumList {
                            try fooEnumListContainer.encode(fooenum0, forKey: Runtime.Key("member"))
                        }
                    }
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `002 encode nested enum`() {
        val context = setupTests("Isolated/Restxml/xml-enums.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlEnumsNestedInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlEnumsNestedInput: Swift.Encodable, Runtime.Reflection {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case nestedEnumsList
                }
            
                public func encode(to encoder: Swift.Encoder) throws {
                    var container = encoder.container(keyedBy: Runtime.Key.self)
                    if let nestedEnumsList = nestedEnumsList {
                        var nestedEnumsListContainer = container.nestedContainer(keyedBy: Runtime.Key.self, forKey: Runtime.Key("nestedEnumsList"))
                        for nestedenumslist0 in nestedEnumsList {
                            var nestedenumslist0Container0 = nestedEnumsListContainer.nestedContainer(keyedBy: Runtime.Key.self, forKey: Runtime.Key("member"))
                            for fooenum1 in nestedenumslist0 {
                                try nestedenumslist0Container0.encode(fooenum1, forKey: Runtime.Key("member"))
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
