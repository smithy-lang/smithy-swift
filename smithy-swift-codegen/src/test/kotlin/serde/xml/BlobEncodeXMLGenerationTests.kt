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
            
                static func writingClosure(_ value: XmlBlobsInput?, to writer: SmithyXML.Writer) throws {
                    guard let value else { writer.detach(); return }
                    try writer[.init("data")].write(value.data)
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
            
                static func writingClosure(_ value: XmlBlobsNestedInput?, to writer: SmithyXML.Writer) throws {
                    guard let value else { writer.detach(); return }
                    try writer[.init("nestedBlobList")].writeList(value.nestedBlobList, memberWritingClosure: SmithyXML.listWritingClosure(memberWritingClosure: ClientRuntime.Data.writingClosure(_:to:), memberNodeInfo: .init("member"), isFlattened: false), memberNodeInfo: .init("member"), isFlattened: false)
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
