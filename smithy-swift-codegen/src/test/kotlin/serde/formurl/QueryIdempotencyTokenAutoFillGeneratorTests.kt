package software.amazon.smithy.aws.swift.codegen.awsquery

import TestContext
import defaultSettings
import getFileContents
import io.kotest.matchers.string.shouldContainOnlyOnce
import mocks.MockHttpAWSQueryProtocolGenerator
import org.junit.jupiter.api.Test
import shouldSyntacticSanityCheck

class QueryIdempotencyTokenAutoFillGeneratorTests {
    @Test
    fun `001 hardcodes action and version into input type`() {
        val context = setupTests("Isolated/formurl/query-idempotency-token.smithy", "aws.protocoltests.query#AwsQuery")
        val contents = getFileContents(context.manifest, "/Example/models/QueryIdempotencyTokenAutoFillInput+Encodable.swift")
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            extension QueryIdempotencyTokenAutoFillInput: Encodable, Reflection {
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: Key.self)
                    if let token = token {
                        try container.encode(token, forKey: Key("token"))
                    }
                    try container.encode("QueryIdempotencyTokenAutoFill", forKey:Key("Action"))
                    try container.encode("2020-01-08", forKey:Key("Version"))
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
        print("smithyFile: $smithyFile")
        print("serviceShapeId: $serviceShapeId")
        val context = TestContext.initContextFrom(smithyFile, serviceShapeId, MockHttpAWSQueryProtocolGenerator()) { model ->
            model.defaultSettings(serviceShapeId, "Example", "2020-01-08", "aws query protocol")
        }
        context.generator.generateCodableConformanceForNestedTypes(context.generationCtx)
        context.generator.generateSerializers(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
