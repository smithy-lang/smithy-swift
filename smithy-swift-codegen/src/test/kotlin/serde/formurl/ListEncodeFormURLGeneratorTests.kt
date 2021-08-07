package software.amazon.smithy.aws.swift.codegen.awsquery

import TestContext
import defaultSettings
import getFileContents
import io.kotest.matchers.string.shouldContainOnlyOnce
import mocks.MockHttpAWSQueryProtocolGenerator
import org.junit.jupiter.api.Test
import shouldSyntacticSanityCheck

class ListEncodeFormURLGeneratorTests {
    @Test
    fun `001 encode different types of lists`() {
        val context = setupTests("Isolated/formurl/query-lists.smithy", "aws.protocoltests.query#AwsQuery")
        val contents = getFileContents(context.manifest, "/Example/models/QueryListsInput+Encodable.swift")
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            extension QueryListsInput: Swift.Encodable, Swift.Reflection {
                public func encode(to encoder: Swift.Encoder) throws {
                    var container = encoder.container(keyedBy: ClientRuntime.Key.self)
                    if let complexListArg = complexListArg {
                        var complexListArgContainer = container.nestedContainer(keyedBy: ClientRuntime.Key.self, forKey: ClientRuntime.Key("ComplexListArg"))
                        for (index0, greetingstruct0) in complexListArg.enumerated() {
                            try complexListArgContainer.encode(greetingstruct0, forKey: ClientRuntime.Key("member.\(index0.advanced(by: 1))"))
                        }
                    }
                    if let flattenedListArg = flattenedListArg {
                        if !flattenedListArg.isEmpty {
                            for (index0, string0) in flattenedListArg.enumerated() {
                                var flattenedListArgContainer0 = container.nestedContainer(keyedBy: ClientRuntime.Key.self, forKey: ClientRuntime.Key("FlattenedListArg.\(index0.advanced(by: 1))"))
                                try flattenedListArgContainer0.encode(string0, forKey: ClientRuntime.Key(""))
                            }
                        }
                    }
                    if let flattenedListArgWithXmlName = flattenedListArgWithXmlName {
                        if !flattenedListArgWithXmlName.isEmpty {
                            for (index0, string0) in flattenedListArgWithXmlName.enumerated() {
                                var flattenedListArgWithXmlNameContainer0 = container.nestedContainer(keyedBy: ClientRuntime.Key.self, forKey: ClientRuntime.Key("Hi.\(index0.advanced(by: 1))"))
                                try flattenedListArgWithXmlNameContainer0.encode(string0, forKey: ClientRuntime.Key(""))
                            }
                        }
                    }
                    if let listArg = listArg {
                        var listArgContainer = container.nestedContainer(keyedBy: ClientRuntime.Key.self, forKey: ClientRuntime.Key("ListArg"))
                        for (index0, string0) in listArg.enumerated() {
                            try listArgContainer.encode(string0, forKey: ClientRuntime.Key("member.\(index0.advanced(by: 1))"))
                        }
                    }
                    if let listArgWithXmlNameMember = listArgWithXmlNameMember {
                        var listArgWithXmlNameMemberContainer = container.nestedContainer(keyedBy: ClientRuntime.Key.self, forKey: ClientRuntime.Key("ListArgWithXmlNameMember"))
                        for (index0, string0) in listArgWithXmlNameMember.enumerated() {
                            try listArgWithXmlNameMemberContainer.encode(string0, forKey: ClientRuntime.Key("item.\(index0.advanced(by: 1))"))
                        }
                    }
                    if let flatTsList = flatTsList {
                        if !flatTsList.isEmpty {
                            for (index0, timestamp0) in flatTsList.enumerated() {
                                var flatTsListContainer0 = container.nestedContainer(keyedBy: ClientRuntime.Key.self, forKey: ClientRuntime.Key("flatTsList.\(index0.advanced(by: 1))"))
                                try flatTsListContainer0.encode(TimestampWrapper(timestamp0, format: .epochSeconds), forKey: ClientRuntime.Key(""))
                            }
                        }
                    }
                    if let tsList = tsList {
                        var tsListContainer = container.nestedContainer(keyedBy: ClientRuntime.Key.self, forKey: ClientRuntime.Key("tsList"))
                        for (index0, timestamp0) in tsList.enumerated() {
                            try tsListContainer.encode(TimestampWrapper(timestamp0, format: .epochSeconds), forKey: ClientRuntime.Key("member.\(index0.advanced(by: 1))"))
                        }
                    }
                    try container.encode("QueryLists", forKey:ClientRuntime.Key("Action"))
                    try container.encode("2020-01-08", forKey:ClientRuntime.Key("Version"))
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
