package serde.ec2

import TestContext
import defaultSettings
import getFileContents
import io.kotest.matchers.string.shouldContainOnlyOnce
import mocks.MockHttpEC2QueryProtocolGenerator
import org.junit.jupiter.api.Test
import shouldSyntacticSanityCheck

class Ec2QueryNameTests {
    @Test
    fun `001 encode simple types`() {
        val context = setupTests("Isolated/ec2/query-simple.smithy", "aws.protocoltests.ec2#AwsEc2")
        val contents = getFileContents(context.manifest, "/Example/models/Ec2SimpleInputParamsInput+Encodable.swift")
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            extension Ec2SimpleInputParamsInput: Encodable, Reflection {
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: Key.self)
                    if let bamInt = bamInt {
                        try container.encode(bamInt, forKey: Key("BamInt"))
                    }
                    if let barString = barString {
                        try container.encode(barString, forKey: Key("BarString"))
                    }
                    if let bazBoolean = bazBoolean {
                        try container.encode(bazBoolean, forKey: Key("BazBoolean"))
                    }
                    if let booDouble = booDouble {
                        try container.encode(booDouble, forKey: Key("BooDouble"))
                    }
                    if let fzzEnum = fzzEnum {
                        try container.encode(fzzEnum, forKey: Key("FzzEnum"))
                    }
                    if let hasQueryAndXmlNameString = hasQueryAndXmlNameString {
                        try container.encode(hasQueryAndXmlNameString, forKey: Key("B"))
                    }
                    if let hasQueryNameString = hasQueryNameString {
                        try container.encode(hasQueryNameString, forKey: Key("A"))
                    }
                    if let quxBlob = quxBlob {
                        try container.encode(quxBlob.base64EncodedString(), forKey: Key("QuxBlob"))
                    }
                    if let usesXmlNameString = usesXmlNameString {
                        try container.encode(usesXmlNameString, forKey: Key("C"))
                    }
                    try container.encode("Ec2SimpleInputParams", forKey:Key("Action"))
                    try container.encode("2020-01-08", forKey:Key("Version"))
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }
    private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
        val context = TestContext.initContextFrom(smithyFile, serviceShapeId, MockHttpEC2QueryProtocolGenerator()) { model ->
            model.defaultSettings(serviceShapeId, "Example", "2020-01-08", "Ec2 query protocol")
        }
        context.generator.generateCodableConformanceForNestedTypes(context.generationCtx)
        context.generator.generateSerializers(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
