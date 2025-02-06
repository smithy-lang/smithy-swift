package software.amazon.smithy.swift.codegen.protocolspecificserde.xml

/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test
import software.amazon.smithy.swift.codegen.getFileContents

class EnumDecodeXMLGenerationTests {
    @Test
    fun `decode enum`() {
        val context = setupTests("Isolated/Restxml/xml-enums.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlEnumsOutput+HttpResponseBinding.swift")
        val expectedContents = """
extension XmlEnumsOutput {

    static func httpOutput(from httpResponse: SmithyHTTPAPI.HTTPResponse) async throws -> XmlEnumsOutput {
        let data = try await httpResponse.data()
        let responseReader = try SmithyXML.Reader.from(data: data)
        let reader = responseReader
        var value = XmlEnumsOutput()
        value.fooEnum1 = try reader["fooEnum1"].readIfPresent()
        value.fooEnum2 = try reader["fooEnum2"].readIfPresent()
        value.fooEnum3 = try reader["fooEnum3"].readIfPresent()
        value.fooEnumList = try reader["fooEnumList"].readListIfPresent(memberReadingClosure: SmithyReadWrite.ReadingClosureBox<RestXmlProtocolClientTypes.FooEnum>().read(from:), memberNodeInfo: "member", isFlattened: false)
        return value
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `decode enum nested`() {
        val context = setupTests("Isolated/Restxml/xml-enums.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlEnumsNestedOutput+HttpResponseBinding.swift")
        val expectedContents = """
extension XmlEnumsNestedOutput {

    static func httpOutput(from httpResponse: SmithyHTTPAPI.HTTPResponse) async throws -> XmlEnumsNestedOutput {
        let data = try await httpResponse.data()
        let responseReader = try SmithyXML.Reader.from(data: data)
        let reader = responseReader
        var value = XmlEnumsNestedOutput()
        value.nestedEnumsList = try reader["nestedEnumsList"].readListIfPresent(memberReadingClosure: SmithyReadWrite.listReadingClosure(memberReadingClosure: SmithyReadWrite.ReadingClosureBox<RestXmlProtocolClientTypes.FooEnum>().read(from:), memberNodeInfo: "member", isFlattened: false), memberNodeInfo: "member", isFlattened: false)
        return value
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }
}
