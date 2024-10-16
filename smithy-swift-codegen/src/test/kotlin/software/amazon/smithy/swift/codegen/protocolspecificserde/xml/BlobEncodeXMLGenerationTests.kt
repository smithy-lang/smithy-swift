package software.amazon.smithy.swift.codegen.protocolspecificserde.xml

/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test
import software.amazon.smithy.swift.codegen.getFileContents

class BlobEncodeXMLGenerationTests {
    @Test
    fun `encode blob`() {
        val context = setupTests("Isolated/Restxml/xml-blobs.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlBlobsInput+Write.swift")
        val expectedContents = """
extension XmlBlobsInput {

    static func write(value: XmlBlobsInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { return }
        try writer["data"].write(value.data)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `encode nested blob`() {
        val context = setupTests("Isolated/Restxml/xml-blobs.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlBlobsNestedInput+Write.swift")
        val expectedContents = """
extension XmlBlobsNestedInput {

    static func write(value: XmlBlobsNestedInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { return }
        try writer["nestedBlobList"].writeList(value.nestedBlobList, memberWritingClosure: SmithyReadWrite.listWritingClosure(memberWritingClosure: SmithyReadWrite.WritingClosures.writeData(value:to:), memberNodeInfo: "member", isFlattened: false), memberNodeInfo: "member", isFlattened: false)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }
}
