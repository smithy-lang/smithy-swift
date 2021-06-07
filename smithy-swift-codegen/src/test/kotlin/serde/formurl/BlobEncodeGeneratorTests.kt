package serde.formurl

import TestContext
import defaultSettings
import getFileContents
import io.kotest.matchers.string.shouldContainOnlyOnce
import mocks.MockHttpAWSQueryProtocolGenerator
import org.junit.jupiter.api.Test
import shouldSyntacticSanityCheck

class BlobEncodeGeneratorTests {
    @Test
    fun `001 encode blobs`() {
        val context = setupTests("Isolated/formurl/query-blobs.smithy", "aws.protocoltests.query#AwsQuery")
        val contents = getFileContents(context.manifest, "/Example/models/BlobInputParamsInput+Encodable.swift")
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            extension BlobInputParamsInput: Encodable, Reflection {
                enum CodingKeys: String, CodingKey {
                    case blobList = "BlobList"
                    case blobListFlattened = "BlobListFlattened"
                    case blobMap = "BlobMap"
                    case blobMapFlattened = "BlobMapFlattened"
                    case blobMember = "BlobMember"
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: Key.self)
                    if let blobList = blobList {
                        var blobListContainer = container.nestedContainer(keyedBy: Key.self, forKey: Key("BlobList"))
                        for (index0, blob0) in blobList.enumerated() {
                            try blobListContainer.encode(blob0.base64EncodedString(), forKey: Key("member.\(index0.advanced(by: 1))"))
                        }
                    }
                    if let blobListFlattened = blobListFlattened {
                        if !blobListFlattened.isEmpty {
                            for (index0, blob0) in blobListFlattened.enumerated() {
                                try container.encode(blob0.base64EncodedString(), forKey: Key("BlobListFlattened.\(index0.advanced(by: 1))"))
                            }
                        }
                    }
                    if let blobMap = blobMap {
                        var blobMapContainer = container.nestedContainer(keyedBy: Key.self, forKey: Key("BlobMap"))
                        for (index0, element0) in blobMap.sorted(by: { ${'$'}0.key < ${'$'}1.key }).enumerated() {
                            let stringKey0 = element0.key
                            let blobValue0 = element0.value
                            var entryContainer0 = blobMapContainer.nestedContainer(keyedBy: Key.self, forKey: Key("entry.\(index0.advanced(by: 1))"))
                            var keyContainer0 = entryContainer0.nestedContainer(keyedBy: Key.self, forKey: Key("key"))
                            try keyContainer0.encode(stringKey0, forKey: Key(""))
                            var valueContainer0 = entryContainer0.nestedContainer(keyedBy: Key.self, forKey: Key("value"))
                            try valueContainer0.encode(blobValue0.base64EncodedString(), forKey: Key(""))
                        }
                    }
                    if let blobMapFlattened = blobMapFlattened {
                        if !blobMapFlattened.isEmpty {
                            for (index0, element0) in blobMapFlattened.sorted(by: { ${'$'}0.key < ${'$'}1.key }).enumerated() {
                                let stringKey0 = element0.key
                                let blobValue0 = element0.value
                                var nestedContainer0 = container.nestedContainer(keyedBy: Key.self, forKey: Key("BlobMapFlattened.\(index0.advanced(by: 1))"))
                                var keyContainer0 = nestedContainer0.nestedContainer(keyedBy: Key.self, forKey: Key("key"))
                                try keyContainer0.encode(stringKey0, forKey: Key(""))
                                var valueContainer0 = nestedContainer0.nestedContainer(keyedBy: Key.self, forKey: Key("value"))
                                try valueContainer0.encode(blobValue0.base64EncodedString(), forKey: Key(""))
                            }
                        }
                    }
                    if let blobMember = blobMember {
                        try container.encode(blobMember.base64EncodedString(), forKey: Key("BlobMember"))
                    }
                    try container.encode("BlobInputParams", forKey:Key("Action"))
                    try container.encode("2020-01-08", forKey:Key("Version"))
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
        val context = TestContext.initContextFrom(smithyFile, serviceShapeId, MockHttpAWSQueryProtocolGenerator()) { model ->
            model.defaultSettings(serviceShapeId, "Example", "2020-01-08", "aws query protocol")
        }
        context.generator.generateCodableConformanceForNestedTypes(context.generationCtx)
        context.generator.generateSerializers(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
