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

class UnionEncodeXMLGenerationTests {
    @Test
    fun `001 XmlUnionShape+Codable`() {
        val context = setupTests("Isolated/Restxml/xml-unions.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlUnionShape+ReadWrite.swift")
        val expectedContents = """
extension RestXmlProtocolClientTypes.XmlUnionShape {

    static func writingClosure(_ value: RestXmlProtocolClientTypes.XmlUnionShape?, to writer: SmithyXML.Writer) throws {
        guard let value else { writer.detach(); return }
        switch value {
            case let .datavalue(datavalue):
                try writer["dataValue"].write(datavalue)
            case let .doublevalue(doublevalue):
                try writer["doubleValue"].write(doublevalue)
            case let .mapvalue(mapvalue):
                try writer["mapValue"].writeMap(mapvalue, valueWritingClosure: Swift.String.writingClosure(_:to:), keyNodeInfo: "K", valueNodeInfo: "V", isFlattened: false)
            case let .stringlist(stringlist):
                try writer["stringList"].writeList(stringlist, memberWritingClosure: Swift.String.writingClosure(_:to:), memberNodeInfo: "member", isFlattened: false)
            case let .structvalue(structvalue):
                try writer["structValue"].write(structvalue, writingClosure: RestXmlProtocolClientTypes.XmlNestedUnionStruct.writingClosure(_:to:))
            case let .timestampvalue(timestampvalue):
                try writer["timeStampValue"].writeTimestamp(timestampvalue, format: .dateTime)
            case let .unionvalue(unionvalue):
                try writer["unionValue"].write(unionvalue, writingClosure: RestXmlProtocolClientTypes.XmlUnionShape.writingClosure(_:to:))
            case let .sdkUnknown(sdkUnknown):
                try writer["sdkUnknown"].write(sdkUnknown)
        }
    }

    static var readingClosure: SmithyReadWrite.ReadingClosure<RestXmlProtocolClientTypes.XmlUnionShape, SmithyXML.Reader> {
        return { reader in
            guard reader.content != nil else { return nil }
            let name = reader.children.first?.nodeInfo.name
            switch name {
                case "doubleValue":
                    return .doublevalue(try reader["doubleValue"].read())
                case "dataValue":
                    return .datavalue(try reader["dataValue"].read())
                case "unionValue":
                    return .unionvalue(try reader["unionValue"].read(readingClosure: RestXmlProtocolClientTypes.XmlUnionShape.readingClosure))
                case "structValue":
                    return .structvalue(try reader["structValue"].read(readingClosure: RestXmlProtocolClientTypes.XmlNestedUnionStruct.readingClosure))
                case "mapValue":
                    return .mapvalue(try reader["mapValue"].readMap(valueReadingClosure: Swift.String.readingClosure, keyNodeInfo: "K", valueNodeInfo: "V", isFlattened: false))
                case "stringList":
                    return .stringlist(try reader["stringList"].readList(memberReadingClosure: Swift.String.readingClosure, memberNodeInfo: "member", isFlattened: false))
                case "timeStampValue":
                    return .timestampvalue(try reader["timeStampValue"].readTimestamp(format: .dateTime))
                default:
                    return .sdkUnknown(name ?? "")
            }
        }
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `002 XmlUnionShape should be marked as indirect`() {
        val context = setupTests("Isolated/Restxml/xml-unions.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlUnionShape.swift")
        val expectedContents =
            """
            extension ExampleClientTypes {
                public indirect enum XmlUnionShape: Swift.Equatable {
                    case doublevalue(Swift.Double)
                    case datavalue(ClientRuntime.Data)
                    case unionvalue(ExampleClientTypes.XmlUnionShape)
                    case structvalue(ExampleClientTypes.XmlNestedUnionStruct)
                    case mapvalue([Swift.String:Swift.String])
                    case stringlist([Swift.String])
                    case timestampvalue(ClientRuntime.Date)
                    case sdkUnknown(Swift.String)
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
        context.generator.generateSerializers(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
