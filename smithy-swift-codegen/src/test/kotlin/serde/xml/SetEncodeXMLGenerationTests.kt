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
import listFilesFromManifest
import org.junit.jupiter.api.Test

class SetEncodeXMLGenerationTests {
    @Test
    fun `001 wrapped set serialization`() {
        val context = setupTests("Isolated/Restxml/xml-sets.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlEnumSetInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlEnumSetInput: Swift.Encodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case fooEnumSet
                }
            
                public func encode(to encoder: Swift.Encoder) throws {
                    var container = encoder.container(keyedBy: ClientRuntime.Key.self)
                    if let fooEnumSet = fooEnumSet {
                        var fooEnumSetContainer = container.nestedContainer(keyedBy: ClientRuntime.Key.self, forKey: ClientRuntime.Key("fooEnumSet"))
                        for fooenum0 in fooEnumSet {
                            try fooEnumSetContainer.encode(fooenum0, forKey: ClientRuntime.Key("member"))
                        }
                    }
                }
            }
            """.trimIndent()

        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `002 wrapped nested set serialization`() {
        val context = setupTests("Isolated/Restxml/xml-sets-nested.smithy", "aws.protocoltests.restxml#RestXml")
        print(listFilesFromManifest(context.manifest))
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlEnumNestedSetInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlEnumNestedSetInput: Swift.Encodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case fooEnumSet
                }
            
                public func encode(to encoder: Swift.Encoder) throws {
                    var container = encoder.container(keyedBy: ClientRuntime.Key.self)
                    if let fooEnumSet = fooEnumSet {
                        var fooEnumSetContainer = container.nestedContainer(keyedBy: ClientRuntime.Key.self, forKey: ClientRuntime.Key("fooEnumSet"))
                        for fooenumset0 in fooEnumSet {
                            var fooenumset0Container0 = fooEnumSetContainer.nestedContainer(keyedBy: ClientRuntime.Key.self, forKey: ClientRuntime.Key("member"))
                            for fooenum1 in fooenumset0 {
                                try fooenumset0Container0.encode(fooenum1, forKey: ClientRuntime.Key("member"))
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
