package software.amazon.smithy.swift.codegen.protocolspecificserde.xml

/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test
import software.amazon.smithy.swift.codegen.getFileContents

class RecursiveShapesDecodeXMLGenerationTests {
    @Test
    fun `decode recursive shape`() {
        val context = setupTests("Isolated/Restxml/xml-recursive.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlRecursiveShapesOutput+HttpResponseBinding.swift")
        val expectedContents = """
extension XmlRecursiveShapesOutput {

    static func httpOutput(from httpResponse: SmithyHTTPAPI.HTTPResponse) async throws -> XmlRecursiveShapesOutput {
        let data = try await httpResponse.data()
        let responseReader = try SmithyXML.Reader.from(data: data)
        let reader = responseReader
        var value = XmlRecursiveShapesOutput()
        value.nested = try reader["nested"].readIfPresent(with: RestXmlProtocolClientTypes.RecursiveShapesInputOutputNested1.read(from:))
        return value
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `decode recursive nested shape`() {
        val context = setupTests("Isolated/Restxml/xml-recursive-nested.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlNestedRecursiveShapesOutput+HttpResponseBinding.swift")
        val expectedContents = """
extension XmlNestedRecursiveShapesOutput {

    static func httpOutput(from httpResponse: SmithyHTTPAPI.HTTPResponse) async throws -> XmlNestedRecursiveShapesOutput {
        let data = try await httpResponse.data()
        let responseReader = try SmithyXML.Reader.from(data: data)
        let reader = responseReader
        var value = XmlNestedRecursiveShapesOutput()
        value.nestedRecursiveList = try reader["nestedRecursiveList"].readListIfPresent(memberReadingClosure: SmithyReadWrite.listReadingClosure(memberReadingClosure: RestXmlProtocolClientTypes.RecursiveShapesInputOutputNested1.read(from:), memberNodeInfo: "member", isFlattened: false), memberNodeInfo: "member", isFlattened: false)
        return value
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }
}
