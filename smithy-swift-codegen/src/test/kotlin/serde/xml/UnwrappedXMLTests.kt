package serde.xml

import MockHttpRestXMLProtocolGenerator
import TestContext
import defaultSettings
import getFileContents
import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test

class UnwrappedXMLTests {
    @Test
    fun `001 S3UnwrappedXmlOutputTrait`() {
        val context = setupTests("Isolated/s3unwrappedxmloutput.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/GetBucketLocationOutputResponseBody+Decodable.swift")

        val expectedContents =
            """
            extension GetBucketLocationOutputResponseBody: Swift.Decodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case locationConstraint = "LocationConstraint"
                }
            
                public init (from decoder: Swift.Decoder) throws {
                    var containerValues = try decoder.unkeyedContainer()
                    let locationConstraintDecoded = try containerValues.decodeIfPresent(RestXmlProtocolClientTypes.BucketLocationConstraint.self)
                    locationConstraint = locationConstraintDecoded
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
        context.generator.generateDeserializers(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
