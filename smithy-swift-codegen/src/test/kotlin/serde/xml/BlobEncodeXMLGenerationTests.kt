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

class BlobEncodeXMLGenerationTests {
    @Test
    fun `encode blob`() {
        val context = setupTests("Isolated/Restxml/xml-blobs.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlBlobsInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlBlobsInput: Swift.Encodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case data
                }
            
                public func encode(to encoder: Swift.Encoder) throws {
                    var container = encoder.container(keyedBy: ClientRuntime.Key.self)
                    if let data = data {
                        try container.encode(data, forKey: ClientRuntime.Key("data"))
                    }
                }
            }
            """.trimIndent()

        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `encode nested blob`() {
        val context = setupTests("Isolated/Restxml/xml-blobs.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlBlobsNestedInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlBlobsNestedInput: Swift.Encodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case nestedBlobList
                }
            
                public func encode(to encoder: Swift.Encoder) throws {
                    var container = encoder.container(keyedBy: ClientRuntime.Key.self)
                    if let nestedBlobList = nestedBlobList {
                        var nestedBlobListContainer = container.nestedContainer(keyedBy: ClientRuntime.Key.self, forKey: ClientRuntime.Key("nestedBlobList"))
                        for nestedbloblist0 in nestedBlobList {
                            var nestedbloblist0Container0 = nestedBlobListContainer.nestedContainer(keyedBy: ClientRuntime.Key.self, forKey: ClientRuntime.Key("member"))
                            for blob1 in nestedbloblist0 {
                                try nestedbloblist0Container0.encode(blob1, forKey: ClientRuntime.Key("member"))
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
