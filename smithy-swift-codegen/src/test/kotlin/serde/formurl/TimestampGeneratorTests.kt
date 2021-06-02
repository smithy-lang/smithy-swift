package serde.formurl

import TestContext
import defaultSettings
import getFileContents
import io.kotest.matchers.string.shouldContainOnlyOnce
import mocks.MockHttpAWSQueryProtocolGenerator
import org.junit.jupiter.api.Test
import shouldSyntacticSanityCheck

class TimestampGeneratorTests {
    @Test
    fun `001 encode timestamps`() {
        val context = setupTests("Isolated/formurl/query-timestamp.smithy", "aws.protocoltests.query#AwsQuery")
        val contents = getFileContents(context.manifest, "/Example/models/QueryTimestampsInput+Encodable.swift")
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            extension QueryTimestampsInput: Encodable, Reflection {
                enum CodingKeys: String, CodingKey {
                    case epochMember
                    case epochTarget
                    case normalFormat
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: Key.self)
                    if let epochMember = epochMember {
                        try container.encode(TimestampWrapper(epochMember, format: .epochSeconds), forKey: Key("epochMember"))
                    }
                    if let epochTarget = epochTarget {
                        try container.encode(TimestampWrapper(epochTarget, format: .epochSeconds), forKey: Key("epochTarget"))
                    }
                    if let normalFormat = normalFormat {
                        try container.encode(TimestampWrapper(normalFormat, format: .dateTime), forKey: Key("normalFormat"))
                    }
                    try container.encode("QueryTimestamps", forKey:Key("Action"))
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
