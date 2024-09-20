package software.amazon.smithy.swift.codegen.protocolspecificserde.xml

/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test
import software.amazon.smithy.swift.codegen.getFileContents

class EnumEncodeXMLGenerationTests {
    @Test
    fun `001 encode enum`() {
        val context = setupTests("Isolated/Restxml/xml-enums.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlEnumsInput+Write.swift")
        val expectedContents = """
extension XmlEnumsInput {

    static func write(value: XmlEnumsInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { return }
        try writer["fooEnum1"].write(value.fooEnum1)
        try writer["fooEnum2"].write(value.fooEnum2)
        try writer["fooEnum3"].write(value.fooEnum3)
        try writer["fooEnumList"].writeList(value.fooEnumList, memberWritingClosure: SmithyReadWrite.WritingClosureBox<RestXmlProtocolClientTypes.FooEnum>().write(value:to:), memberNodeInfo: "member", isFlattened: false)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `002 encode nested enum`() {
        val context = setupTests("Isolated/Restxml/xml-enums.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlEnumsNestedInput+Write.swift")
        val expectedContents = """
extension XmlEnumsNestedInput {

    static func write(value: XmlEnumsNestedInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { return }
        try writer["nestedEnumsList"].writeList(value.nestedEnumsList, memberWritingClosure: SmithyReadWrite.listWritingClosure(memberWritingClosure: SmithyReadWrite.WritingClosureBox<RestXmlProtocolClientTypes.FooEnum>().write(value:to:), memberNodeInfo: "member", isFlattened: false), memberNodeInfo: "member", isFlattened: false)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }
}
