package serde.ec2

import TestContext
import defaultSettings
import getFileContents
import io.kotest.matchers.string.shouldContainOnlyOnce
import mocks.MockHttpEC2QueryProtocolGenerator
import org.junit.jupiter.api.Test
import shouldSyntacticSanityCheck

class OnlyFlattenedListEncodeFormURLGeneratorTests {

    @Test
    fun `001 encode different types of lists`() {
        val context = setupTests("Isolated/ec2/query-lists.smithy", "aws.protocoltests.ec2#AwsEc2")
        val contents = getFileContents(context.manifest, "/Example/models/Ec2QueryListsInput+Encodable.swift")
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            extension Ec2QueryListsInput: Encodable, Reflection {
                enum CodingKeys: String, CodingKey {
                    case complexListArg = "ComplexListArg"
                    case listArg = "ListArg"
                    case listArgWithXmlName = "Hi"
                    case listArgWithXmlNameMember = "ListArgWithXmlNameMember"
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: Key.self)
                    if let complexListArg = complexListArg {
                        if !complexListArg.isEmpty {
                            for (index0, greetingstruct0) in complexListArg.enumerated() {
                                var complexListArgContainer0 = container.nestedContainer(keyedBy: Key.self, forKey: Key("ComplexListArg.\(index0.advanced(by: 1))"))
                                try complexListArgContainer0.encode(greetingstruct0, forKey: Key(""))
                            }
                        }
                    }
                    if let listArg = listArg {
                        if !listArg.isEmpty {
                            for (index0, string0) in listArg.enumerated() {
                                var listArgContainer0 = container.nestedContainer(keyedBy: Key.self, forKey: Key("ListArg.\(index0.advanced(by: 1))"))
                                try listArgContainer0.encode(string0, forKey: Key(""))
                            }
                        }
                    }
                    if let listArgWithXmlName = listArgWithXmlName {
                        if !listArgWithXmlName.isEmpty {
                            for (index0, string0) in listArgWithXmlName.enumerated() {
                                var listArgWithXmlNameContainer0 = container.nestedContainer(keyedBy: Key.self, forKey: Key("Hi.\(index0.advanced(by: 1))"))
                                try listArgWithXmlNameContainer0.encode(string0, forKey: Key(""))
                            }
                        }
                    }
                    if let listArgWithXmlNameMember = listArgWithXmlNameMember {
                        if !listArgWithXmlNameMember.isEmpty {
                            for (index0, string0) in listArgWithXmlNameMember.enumerated() {
                                var listArgWithXmlNameMemberContainer0 = container.nestedContainer(keyedBy: Key.self, forKey: Key("ListArgWithXmlNameMember.\(index0.advanced(by: 1))"))
                                try listArgWithXmlNameMemberContainer0.encode(string0, forKey: Key(""))
                            }
                        }
                    }
                    try container.encode("Ec2QueryLists", forKey:Key("Action"))
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
