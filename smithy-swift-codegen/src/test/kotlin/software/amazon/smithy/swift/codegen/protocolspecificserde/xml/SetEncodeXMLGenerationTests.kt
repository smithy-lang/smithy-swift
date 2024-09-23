package software.amazon.smithy.swift.codegen.protocolspecificserde.xml

/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test
import software.amazon.smithy.swift.codegen.getFileContents

class SetEncodeXMLGenerationTests {
    @Test
    fun `001 wrapped set serialization`() {
        val context = setupTests("Isolated/Restxml/xml-sets.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlEnumSetInput+Write.swift")
        val expectedContents = """
extension XmlEnumSetInput {

    static func write(value: XmlEnumSetInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { return }
        try writer["fooEnumSet"].writeList(value.fooEnumSet, memberWritingClosure: SmithyReadWrite.WritingClosureBox<RestXmlProtocolClientTypes.FooEnum>().write(value:to:), memberNodeInfo: "member", isFlattened: false)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `002 wrapped nested set serialization`() {
        val context = setupTests("Isolated/Restxml/xml-sets-nested.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlEnumNestedSetInput+Write.swift")
        val expectedContents = """
extension XmlEnumNestedSetInput {

    static func write(value: XmlEnumNestedSetInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { return }
        try writer["fooEnumSet"].writeList(value.fooEnumSet, memberWritingClosure: SmithyReadWrite.listWritingClosure(memberWritingClosure: SmithyReadWrite.WritingClosureBox<RestXmlProtocolClientTypes.FooEnum>().write(value:to:), memberNodeInfo: "member", isFlattened: false), memberNodeInfo: "member", isFlattened: false)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }
}
