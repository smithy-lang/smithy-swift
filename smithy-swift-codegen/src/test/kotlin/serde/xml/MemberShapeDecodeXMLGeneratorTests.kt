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

class MemberShapeDecodeXMLGeneratorTests {

    @Test
    fun `001 set default value for a missing value of a scalar member`() {
        val context = setupTests("Isolated/Restxml/xml-scalarmember-default-value.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/SimpleScalarPropertiesOutputResponseBody+Decodable.swift")
        val expectedContents =
            """
        extension SimpleScalarPropertiesOutputResponseBody: Swift.Decodable {
            enum CodingKeys: Swift.String, Swift.CodingKey {
                case byteValue
                case doubleValue = "DoubleDribble"
                case falseBooleanValue
                case floatValue
                case integerValue
                case longValue
                case `protocol` = "protocol"
                case shortValue
                case stringValue
                case trueBooleanValue
            }
        
            public init(from decoder: Swift.Decoder) throws {
                let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                let stringValueDecoded = try containerValues.decodeIfPresent(Swift.String.self, forKey: .stringValue) ?? test
                stringValue = stringValueDecoded
                let trueBooleanValueDecoded = try containerValues.decodeIfPresent(Swift.Bool.self, forKey: .trueBooleanValue) ?? false
                trueBooleanValue = trueBooleanValueDecoded
                let falseBooleanValueDecoded = try containerValues.decodeIfPresent(Swift.Bool.self, forKey: .falseBooleanValue)
                falseBooleanValue = falseBooleanValueDecoded
                let byteValueDecoded = try containerValues.decodeIfPresent(Swift.Int8.self, forKey: .byteValue)
                byteValue = byteValueDecoded
                let shortValueDecoded = try containerValues.decodeIfPresent(Swift.Int16.self, forKey: .shortValue)
                shortValue = shortValueDecoded
                let integerValueDecoded = try containerValues.decodeIfPresent(Swift.Int.self, forKey: .integerValue) ?? 5
                integerValue = integerValueDecoded
                let longValueDecoded = try containerValues.decodeIfPresent(Swift.Int.self, forKey: .longValue)
                longValue = longValueDecoded
                let floatValueDecoded = try containerValues.decodeIfPresent(Swift.Float.self, forKey: .floatValue) ?? 2.4
                floatValue = floatValueDecoded
                let protocolDecoded = try containerValues.decodeIfPresent(Swift.String.self, forKey: .protocol)
                `protocol` = protocolDecoded
                let doubleValueDecoded = try containerValues.decodeIfPresent(Swift.Double.self, forKey: .doubleValue)
                doubleValue = doubleValueDecoded
            }
        }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }
    private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
        val context = TestContext.initContextFrom(smithyFile, serviceShapeId, MockHttpRestXMLProtocolGenerator()) { model ->
            model.defaultSettings(serviceShapeId, "RestXml", "2023-08-08", "Rest Xml Protocol")
        }
        context.generator.generateDeserializers(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
