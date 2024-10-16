package software.amazon.smithy.swift.codegen.protocolspecificserde.xml

/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test
import software.amazon.smithy.swift.codegen.getFileContents

class SetDecodeXMLGenerationTests {
    @Test
    fun `XmlEnumSetOutputBody decodable`() {
        val context = setupTests("Isolated/Restxml/xml-sets.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlEnumSetOutput+HttpResponseBinding.swift")
        val expectedContents = """
extension XmlEnumSetOutput {

    static func httpOutput(from httpResponse: SmithyHTTPAPI.HTTPResponse) async throws -> XmlEnumSetOutput {
        let data = try await httpResponse.data()
        let responseReader = try SmithyXML.Reader.from(data: data)
        let reader = responseReader
        var value = XmlEnumSetOutput()
        value.fooEnumSet = try reader["fooEnumSet"].readListIfPresent(memberReadingClosure: SmithyReadWrite.ReadingClosureBox<RestXmlProtocolClientTypes.FooEnum>().read(from:), memberNodeInfo: "member", isFlattened: false)
        return value
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `XmlEnumNestedSetOutputBody nested decodable`() {
        val context = setupTests("Isolated/Restxml/xml-sets-nested.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlEnumNestedSetOutput+HttpResponseBinding.swift")
        val expectedContents = """
extension XmlEnumNestedSetOutput {

    static func httpOutput(from httpResponse: SmithyHTTPAPI.HTTPResponse) async throws -> XmlEnumNestedSetOutput {
        let data = try await httpResponse.data()
        let responseReader = try SmithyXML.Reader.from(data: data)
        let reader = responseReader
        var value = XmlEnumNestedSetOutput()
        value.fooEnumSet = try reader["fooEnumSet"].readListIfPresent(memberReadingClosure: SmithyReadWrite.listReadingClosure(memberReadingClosure: SmithyReadWrite.ReadingClosureBox<RestXmlProtocolClientTypes.FooEnum>().read(from:), memberNodeInfo: "member", isFlattened: false), memberNodeInfo: "member", isFlattened: false)
        return value
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }
}
