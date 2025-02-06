package software.amazon.smithy.swift.codegen.protocolspecificserde.xml

/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test
import software.amazon.smithy.swift.codegen.getFileContents

class StructDecodeXMLGenerationTests {
    @Test
    fun `XmlWrappedListOutputBody decodable`() {
        val context = setupTests("Isolated/Restxml/xml-lists-wrapped.smithy", "aws.protocoltests.restxml#RestXml")

        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlWrappedListOutput+HttpResponseBinding.swift")
        val expectedContents = """
extension XmlWrappedListOutput {

    static func httpOutput(from httpResponse: SmithyHTTPAPI.HTTPResponse) async throws -> XmlWrappedListOutput {
        let data = try await httpResponse.data()
        let responseReader = try SmithyXML.Reader.from(data: data)
        let reader = responseReader
        var value = XmlWrappedListOutput()
        value.myGroceryList = try reader["myGroceryList"].readListIfPresent(memberReadingClosure: SmithyReadWrite.ReadingClosures.readString(from:), memberNodeInfo: "member", isFlattened: false)
        return value
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `SimpleScalarPropertiesOutputBody decodable`() {
        val context = setupTests("Isolated/Restxml/xml-scalar.smithy", "aws.protocoltests.restxml#RestXml")

        val contents = getFileContents(context.manifest, "Sources/RestXml/models/SimpleScalarPropertiesOutput+HttpResponseBinding.swift")
        val expectedContents = """
extension SimpleScalarPropertiesOutput {

    static func httpOutput(from httpResponse: SmithyHTTPAPI.HTTPResponse) async throws -> SimpleScalarPropertiesOutput {
        let data = try await httpResponse.data()
        let responseReader = try SmithyXML.Reader.from(data: data)
        let reader = responseReader
        var value = SimpleScalarPropertiesOutput()
        if let fooHeaderValue = httpResponse.headers.value(for: "X-Foo") {
            value.foo = fooHeaderValue
        }
        value.byteValue = try reader["byteValue"].readIfPresent()
        value.doubleValue = try reader["DoubleDribble"].readIfPresent()
        value.falseBooleanValue = try reader["falseBooleanValue"].readIfPresent()
        value.floatValue = try reader["floatValue"].readIfPresent()
        value.integerValue = try reader["integerValue"].readIfPresent()
        value.longValue = try reader["longValue"].readIfPresent()
        value.`protocol` = try reader["protocol"].readIfPresent()
        value.shortValue = try reader["shortValue"].readIfPresent()
        value.stringValue = try reader["stringValue"].readIfPresent()
        value.trueBooleanValue = try reader["trueBooleanValue"].readIfPresent()
        return value
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `nestednested wrapped list deserialization`() {
        val context = setupTests("Isolated/Restxml/xml-lists-nestednested-wrapped.smithy", "aws.protocoltests.restxml#RestXml")
        val contents =
            getFileContents(context.manifest, "Sources/RestXml/models/XmlNestedNestedWrappedListOutput+HttpResponseBinding.swift")
        val expectedContents = """
extension XmlNestedNestedWrappedListOutput {

    static func httpOutput(from httpResponse: SmithyHTTPAPI.HTTPResponse) async throws -> XmlNestedNestedWrappedListOutput {
        let data = try await httpResponse.data()
        let responseReader = try SmithyXML.Reader.from(data: data)
        let reader = responseReader
        var value = XmlNestedNestedWrappedListOutput()
        value.nestedNestedStringList = try reader["nestedNestedStringList"].readListIfPresent(memberReadingClosure: SmithyReadWrite.listReadingClosure(memberReadingClosure: SmithyReadWrite.listReadingClosure(memberReadingClosure: SmithyReadWrite.ReadingClosures.readString(from:), memberNodeInfo: "member", isFlattened: false), memberNodeInfo: "member", isFlattened: false), memberNodeInfo: "member", isFlattened: false)
        return value
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `empty lists decode`() {
        val context = setupTests("Isolated/Restxml/xml-lists-empty.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlEmptyListsOutput+HttpResponseBinding.swift")
        val expectedContents = """
extension XmlEmptyListsOutput {

    static func httpOutput(from httpResponse: SmithyHTTPAPI.HTTPResponse) async throws -> XmlEmptyListsOutput {
        let data = try await httpResponse.data()
        let responseReader = try SmithyXML.Reader.from(data: data)
        let reader = responseReader
        var value = XmlEmptyListsOutput()
        value.booleanList = try reader["booleanList"].readListIfPresent(memberReadingClosure: SmithyReadWrite.ReadingClosures.readBool(from:), memberNodeInfo: "member", isFlattened: false)
        value.integerList = try reader["integerList"].readListIfPresent(memberReadingClosure: SmithyReadWrite.ReadingClosures.readInt(from:), memberNodeInfo: "member", isFlattened: false)
        value.stringList = try reader["stringList"].readListIfPresent(memberReadingClosure: SmithyReadWrite.ReadingClosures.readString(from:), memberNodeInfo: "member", isFlattened: false)
        value.stringSet = try reader["stringSet"].readListIfPresent(memberReadingClosure: SmithyReadWrite.ReadingClosures.readString(from:), memberNodeInfo: "member", isFlattened: false)
        return value
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }
}
