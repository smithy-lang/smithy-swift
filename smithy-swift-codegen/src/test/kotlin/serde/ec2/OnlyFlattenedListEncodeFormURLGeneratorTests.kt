/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

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
            extension Ec2QueryListsInput: Swift.Encodable, ClientRuntime.Reflection {
                public func encode(to encoder: Swift.Encoder) throws {
                    var container = encoder.container(keyedBy: ClientRuntime.Key.self)
                    if let complexListArg = complexListArg {
                        if !complexListArg.isEmpty {
                            for (index0, greetingstruct0) in complexListArg.enumerated() {
                                var complexListArgContainer0 = container.nestedContainer(keyedBy: ClientRuntime.Key.self, forKey: ClientRuntime.Key("ComplexListArg.\(index0.advanced(by: 1))"))
                                try complexListArgContainer0.encode(greetingstruct0, forKey: ClientRuntime.Key(""))
                            }
                        }
                    }
                    if let listArg = listArg {
                        if !listArg.isEmpty {
                            for (index0, string0) in listArg.enumerated() {
                                var listArgContainer0 = container.nestedContainer(keyedBy: ClientRuntime.Key.self, forKey: ClientRuntime.Key("ListArg.\(index0.advanced(by: 1))"))
                                try listArgContainer0.encode(string0, forKey: ClientRuntime.Key(""))
                            }
                        }
                    }
                    if let listArgWithXmlName = listArgWithXmlName {
                        if !listArgWithXmlName.isEmpty {
                            for (index0, string0) in listArgWithXmlName.enumerated() {
                                var listArgWithXmlNameContainer0 = container.nestedContainer(keyedBy: ClientRuntime.Key.self, forKey: ClientRuntime.Key("Hi.\(index0.advanced(by: 1))"))
                                try listArgWithXmlNameContainer0.encode(string0, forKey: ClientRuntime.Key(""))
                            }
                        }
                    }
                    if let listArgWithXmlNameMember = listArgWithXmlNameMember {
                        if !listArgWithXmlNameMember.isEmpty {
                            for (index0, string0) in listArgWithXmlNameMember.enumerated() {
                                var listArgWithXmlNameMemberContainer0 = container.nestedContainer(keyedBy: ClientRuntime.Key.self, forKey: ClientRuntime.Key("ListArgWithXmlNameMember.\(index0.advanced(by: 1))"))
                                try listArgWithXmlNameMemberContainer0.encode(string0, forKey: ClientRuntime.Key(""))
                            }
                        }
                    }
                    try container.encode("Ec2QueryLists", forKey:ClientRuntime.Key("Action"))
                    try container.encode("2020-01-08", forKey:ClientRuntime.Key("Version"))
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
