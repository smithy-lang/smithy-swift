package software.amazon.smithy.swift.codegen.protocolspecificserde.xml

/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test
import software.amazon.smithy.swift.codegen.getFileContents

class TimeStampDecodeGenerationTests {
    @Test
    fun `001 decode all timestamps`() {
        val context = setupTests("Isolated/Restxml/xml-timestamp.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlTimestampsOutput+HttpResponseBinding.swift")
        val expectedContents = """
extension XmlTimestampsOutput {

    static func httpOutput(from httpResponse: SmithyHTTPAPI.HTTPResponse) async throws -> XmlTimestampsOutput {
        let data = try await httpResponse.data()
        let responseReader = try SmithyXML.Reader.from(data: data)
        let reader = responseReader
        var value = XmlTimestampsOutput()
        value.dateTime = try reader["dateTime"].readTimestampIfPresent(format: SmithyTimestamps.TimestampFormat.dateTime)
        value.epochSeconds = try reader["epochSeconds"].readTimestampIfPresent(format: SmithyTimestamps.TimestampFormat.epochSeconds)
        value.httpDate = try reader["httpDate"].readTimestampIfPresent(format: SmithyTimestamps.TimestampFormat.httpDate)
        value.normal = try reader["normal"].readTimestampIfPresent(format: SmithyTimestamps.TimestampFormat.dateTime)
        return value
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `002 decode nested timestamps`() {
        val context = setupTests("Isolated/Restxml/xml-timestamp-nested.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlTimestampsNestedOutput+HttpResponseBinding.swift")
        val expectedContents = """
extension XmlTimestampsNestedOutput {

    static func httpOutput(from httpResponse: SmithyHTTPAPI.HTTPResponse) async throws -> XmlTimestampsNestedOutput {
        let data = try await httpResponse.data()
        let responseReader = try SmithyXML.Reader.from(data: data)
        let reader = responseReader
        var value = XmlTimestampsNestedOutput()
        value.nestedTimestampList = try reader["nestedTimestampList"].readListIfPresent(memberReadingClosure: SmithyReadWrite.listReadingClosure(memberReadingClosure: SmithyReadWrite.timestampReadingClosure(format: SmithyTimestamps.TimestampFormat.epochSeconds), memberNodeInfo: "member", isFlattened: false), memberNodeInfo: "member", isFlattened: false)
        return value
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `003 decode nested timestamps HttpDate`() {
        val context = setupTests("Isolated/Restxml/xml-timestamp-nested.smithy", "aws.protocoltests.restxml#RestXml")
        val contents =
            getFileContents(context.manifest, "Sources/RestXml/models/XmlTimestampsNestedHTTPDateOutput+HttpResponseBinding.swift")
        val expectedContents = """
extension XmlTimestampsNestedHTTPDateOutput {

    static func httpOutput(from httpResponse: SmithyHTTPAPI.HTTPResponse) async throws -> XmlTimestampsNestedHTTPDateOutput {
        let data = try await httpResponse.data()
        let responseReader = try SmithyXML.Reader.from(data: data)
        let reader = responseReader
        var value = XmlTimestampsNestedHTTPDateOutput()
        value.nestedTimestampList = try reader["nestedTimestampList"].readListIfPresent(memberReadingClosure: SmithyReadWrite.listReadingClosure(memberReadingClosure: SmithyReadWrite.timestampReadingClosure(format: SmithyTimestamps.TimestampFormat.httpDate), memberNodeInfo: "member", isFlattened: false), memberNodeInfo: "member", isFlattened: false)
        return value
    }
}
"""

        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `004 decode nested timestamps xmlName`() {
        val context = setupTests("Isolated/Restxml/xml-timestamp-nested-xmlname.smithy", "aws.protocoltests.restxml#RestXml")
        val contents =
            getFileContents(context.manifest, "Sources/RestXml/models/XmlTimestampsNestedXmlNameOutput+HttpResponseBinding.swift")
        val expectedContents = """
extension XmlTimestampsNestedXmlNameOutput {

    static func httpOutput(from httpResponse: SmithyHTTPAPI.HTTPResponse) async throws -> XmlTimestampsNestedXmlNameOutput {
        let data = try await httpResponse.data()
        let responseReader = try SmithyXML.Reader.from(data: data)
        let reader = responseReader
        var value = XmlTimestampsNestedXmlNameOutput()
        value.nestedTimestampList = try reader["nestedTimestampList"].readListIfPresent(memberReadingClosure: SmithyReadWrite.listReadingClosure(memberReadingClosure: SmithyReadWrite.timestampReadingClosure(format: SmithyTimestamps.TimestampFormat.epochSeconds), memberNodeInfo: "nestedTag2", isFlattened: false), memberNodeInfo: "nestedTag1", isFlattened: false)
        return value
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }
}
