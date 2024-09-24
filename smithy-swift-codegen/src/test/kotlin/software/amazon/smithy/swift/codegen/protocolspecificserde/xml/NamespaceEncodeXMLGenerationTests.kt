package software.amazon.smithy.swift.codegen.protocolspecificserde.xml

/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test
import software.amazon.smithy.swift.codegen.getFileContents

class NamespaceEncodeXMLGenerationTests {
    @Test
    fun `001 xmlnamespace, XmlNamespacesInput, Encodable`() {
        val context = setupTests("Isolated/Restxml/xml-namespace.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlNamespacesInput+Write.swift")
        val expectedContents = """
extension XmlNamespacesInput {

    static func write(value: XmlNamespacesInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { return }
        try writer[.init("nested", namespaceDef: .init(prefix: "", uri: "http://boo.com"))].write(value.nested, with: RestXmlProtocolClientTypes.XmlNamespaceNested.write(value:to:))
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `003 xmlnamespace, XmlNamespaceNested`() {
        val context = setupTests("Isolated/Restxml/xml-namespace.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlNamespaceNested+ReadWrite.swift")
        val expectedContents = """
extension RestXmlProtocolClientTypes.XmlNamespaceNested {

    static func write(value: RestXmlProtocolClientTypes.XmlNamespaceNested?, to writer: SmithyXML.Writer) throws {
        guard let value else { return }
        try writer[.init("foo", namespaceDef: .init(prefix: "baz", uri: "http://baz.com"))].write(value.foo)
        try writer[.init("values", namespaceDef: .init(prefix: "", uri: "http://qux.com"))].writeList(value.values, memberWritingClosure: SmithyReadWrite.WritingClosures.writeString(value:to:), memberNodeInfo: .init("member", namespaceDef: .init(prefix: "", uri: "http://bux.com")), isFlattened: false)
    }

    static func read(from reader: SmithyXML.Reader) throws -> RestXmlProtocolClientTypes.XmlNamespaceNested {
        guard reader.hasContent else { throw SmithyReadWrite.ReaderError.requiredValueNotPresent }
        var value = RestXmlProtocolClientTypes.XmlNamespaceNested()
        value.foo = try reader[.init("foo", namespaceDef: .init(prefix: "baz", uri: "http://baz.com"))].readIfPresent()
        value.values = try reader[.init("values", namespaceDef: .init(prefix: "", uri: "http://qux.com"))].readListIfPresent(memberReadingClosure: SmithyReadWrite.ReadingClosures.readString(from:), memberNodeInfo: .init("member", namespaceDef: .init(prefix: "", uri: "http://bux.com")), isFlattened: false)
        return value
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `005 xmlnamespace nested list, Encodable`() {
        val context = setupTests("Isolated/Restxml/xml-namespace-nestedlist.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlNamespaceNestedListInput+Write.swift")
        val expectedContents = """
extension XmlNamespaceNestedListInput {

    static func write(value: XmlNamespaceNestedListInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { return }
        try writer[.init("nested", namespaceDef: .init(prefix: "", uri: "http://aux.com"))].writeList(value.nested, memberWritingClosure: SmithyReadWrite.listWritingClosure(memberWritingClosure: SmithyReadWrite.WritingClosures.writeString(value:to:), memberNodeInfo: .init("member", namespaceDef: .init(prefix: "bzzzz", uri: "http://bar.com")), isFlattened: false), memberNodeInfo: .init("member", namespaceDef: .init(prefix: "baz", uri: "http://bux.com")), isFlattened: false)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `007 xmlnamespace nested flattened list, encodable`() {
        val context = setupTests("Isolated/Restxml/xml-namespace-flattenedlist.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlNamespaceFlattenedListInput+Write.swift")
        val expectedContents = """
extension XmlNamespaceFlattenedListInput {

    static func write(value: XmlNamespaceFlattenedListInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { return }
        try writer[.init("nested", namespaceDef: .init(prefix: "baz", uri: "http://aux.com"))].writeList(value.nested, memberWritingClosure: SmithyReadWrite.WritingClosures.writeString(value:to:), memberNodeInfo: "member", isFlattened: true)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `010 xmlnamespace on service, encodable`() {
        val context = setupTests("Isolated/Restxml/xml-namespace-onservice.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlNamespacesOnServiceInput+Write.swift")
        val expectedContents = """
extension XmlNamespacesOnServiceInput {

    static func write(value: XmlNamespacesOnServiceInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { return }
        try writer["foo"].write(value.foo)
        try writer[.init("nested", namespaceDef: .init(prefix: "xsi", uri: "https://example.com"))].write(value.nested, with: RestXmlProtocolClientTypes.NestedWithNamespace.write(value:to:))
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `011 xmlnamespace on service, encodable`() {
        val context = setupTests("Isolated/Restxml/xml-namespace-onservice-overridable.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlNamespacesOnServiceOverridableInput+Write.swift")
        val expectedContents = """
extension XmlNamespacesOnServiceOverridableInput {

    static func write(value: XmlNamespacesOnServiceOverridableInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { return }
        try writer["foo"].write(value.foo)
        try writer[.init("nested", namespaceDef: .init(prefix: "xsi", uri: "https://example.com"))].write(value.nested, with: RestXmlProtocolClientTypes.NestedWithNamespace.write(value:to:))
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }
}
