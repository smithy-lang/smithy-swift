package serde.xml

import MockHttpRestXMLProtocolGenerator
import TestContext
import defaultSettings
import getFileContents
import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test

class BlobDecodeXMLGenerationTests {

    @Test
    fun `decode blob`() {
        val context = setupTests("Isolated/Restxml/xml-blobs.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlBlobsOutputResponseBody+Decodable.swift")
        val expectedContents = """
        extension XmlBlobsOutputResponseBody: Decodable {
            enum CodingKeys: String, CodingKey {
                case data
            }
        
            public init (from decoder: Decoder) throws {
                let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                if containerValues.contains(.data) {
                    do {
                        let dataDecoded = try containerValues.decodeIfPresent(Data.self, forKey: .data)
                        data = dataDecoded
                    } catch {
                        data = "".data(using: .utf8)
                    }
                } else {
                    data = nil
                }
            }
        }
        """.trimIndent()

        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `decode blob nested`() {
        val context = setupTests("Isolated/Restxml/xml-blobs.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlBlobsNestedOutputResponseBody+Decodable.swift")
        val expectedContents = """
        extension XmlBlobsNestedOutputResponseBody: Decodable {
            enum CodingKeys: String, CodingKey {
                case nestedBlobList
            }
        
            public init (from decoder: Decoder) throws {
                let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                if containerValues.contains(.nestedBlobList) {
                    struct KeyVal0{struct member{}}
                    let nestedBlobListWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: CollectionMemberCodingKey<KeyVal0.member>.CodingKeys.self, forKey: .nestedBlobList)
                    if let nestedBlobListWrappedContainer = nestedBlobListWrappedContainer {
                        let nestedBlobListContainer = try nestedBlobListWrappedContainer.decodeIfPresent([[Data]].self, forKey: .member)
                        var nestedBlobListBuffer:[[Data]]? = nil
                        if let nestedBlobListContainer = nestedBlobListContainer {
                            nestedBlobListBuffer = [[Data]]()
                            var listBuffer0: [Data]? = nil
                            for listContainer0 in nestedBlobListContainer {
                                listBuffer0 = [Data]()
                                for blobContainer1 in listContainer0 {
                                    listBuffer0?.append(blobContainer1)
                                }
                                if let listBuffer0 = listBuffer0 {
                                    nestedBlobListBuffer?.append(listBuffer0)
                                }
                            }
                        }
                        nestedBlobList = nestedBlobListBuffer
                    } else {
                        nestedBlobList = []
                    }
                } else {
                    nestedBlobList = nil
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
