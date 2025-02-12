package software.amazon.smithy.swift.codegen.protocolspecificserde.xml

/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test
import software.amazon.smithy.swift.codegen.getFileContents

class MapDecodeXMLGenerationTests {
    @Test
    fun `001 decode wrapped map`() {
        val context = setupTests("Isolated/Restxml/xml-maps.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlMapsOutput+HttpResponseBinding.swift")
        val expectedContents = """
extension XmlMapsOutput {

    static func httpOutput(from httpResponse: SmithyHTTPAPI.HTTPResponse) async throws -> XmlMapsOutput {
        let data = try await httpResponse.data()
        let responseReader = try SmithyXML.Reader.from(data: data)
        let reader = responseReader
        var value = XmlMapsOutput()
        value.myMap = try reader["myMap"].readMapIfPresent(valueReadingClosure: RestXmlProtocolClientTypes.GreetingStruct.read(from:), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false)
        return value
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `002 decode wrapped map with name protocol`() {
        val context = setupTests("Isolated/Restxml/xml-maps.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlMapsWithNameProtocolOutput+HttpResponseBinding.swift")
        val expectedContents = """
extension XmlMapsWithNameProtocolOutput {

    static func httpOutput(from httpResponse: SmithyHTTPAPI.HTTPResponse) async throws -> XmlMapsWithNameProtocolOutput {
        let data = try await httpResponse.data()
        let responseReader = try SmithyXML.Reader.from(data: data)
        let reader = responseReader
        var value = XmlMapsWithNameProtocolOutput()
        value.`protocol` = try reader["protocol"].readMapIfPresent(valueReadingClosure: RestXmlProtocolClientTypes.GreetingStruct.read(from:), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false)
        return value
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `003 decode nested wrapped map`() {
        val context = setupTests("Isolated/Restxml/xml-maps-nested.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlMapsNestedOutput+HttpResponseBinding.swift")
        val expectedContents = """
extension XmlMapsNestedOutput {

    static func httpOutput(from httpResponse: SmithyHTTPAPI.HTTPResponse) async throws -> XmlMapsNestedOutput {
        let data = try await httpResponse.data()
        let responseReader = try SmithyXML.Reader.from(data: data)
        let reader = responseReader
        var value = XmlMapsNestedOutput()
        value.myMap = try reader["myMap"].readMapIfPresent(valueReadingClosure: SmithyReadWrite.mapReadingClosure(valueReadingClosure: RestXmlProtocolClientTypes.GreetingStruct.read(from:), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false)
        return value
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `004 decode nested nested wrapped map`() {
        val context = setupTests("Isolated/Restxml/xml-maps-nestednested.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlMapsNestedNestedOutput+HttpResponseBinding.swift")
        val expectedContents = """
extension XmlMapsNestedNestedOutput {

    static func httpOutput(from httpResponse: SmithyHTTPAPI.HTTPResponse) async throws -> XmlMapsNestedNestedOutput {
        let data = try await httpResponse.data()
        let responseReader = try SmithyXML.Reader.from(data: data)
        let reader = responseReader
        var value = XmlMapsNestedNestedOutput()
        value.myMap = try reader["myMap"].readMapIfPresent(valueReadingClosure: SmithyReadWrite.mapReadingClosure(valueReadingClosure: SmithyReadWrite.mapReadingClosure(valueReadingClosure: RestXmlProtocolClientTypes.GreetingStruct.read(from:), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false)
        return value
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `005 decode flattened map`() {
        val context = setupTests("Isolated/Restxml/xml-maps-flattened.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlFlattenedMapsOutput+HttpResponseBinding.swift")
        val expectedContents = """
extension XmlFlattenedMapsOutput {

    static func httpOutput(from httpResponse: SmithyHTTPAPI.HTTPResponse) async throws -> XmlFlattenedMapsOutput {
        let data = try await httpResponse.data()
        let responseReader = try SmithyXML.Reader.from(data: data)
        let reader = responseReader
        var value = XmlFlattenedMapsOutput()
        value.myMap = try reader["myMap"].readMapIfPresent(valueReadingClosure: RestXmlProtocolClientTypes.GreetingStruct.read(from:), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: true)
        return value
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `006 decode flattened nested map`() {
        val context = setupTests("Isolated/Restxml/xml-maps-flattened-nested.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlMapsFlattenedNestedOutput+HttpResponseBinding.swift")
        val expectedContents = """
extension XmlMapsFlattenedNestedOutput {

    static func httpOutput(from httpResponse: SmithyHTTPAPI.HTTPResponse) async throws -> XmlMapsFlattenedNestedOutput {
        let data = try await httpResponse.data()
        let responseReader = try SmithyXML.Reader.from(data: data)
        let reader = responseReader
        var value = XmlMapsFlattenedNestedOutput()
        value.myMap = try reader["myMap"].readMapIfPresent(valueReadingClosure: SmithyReadWrite.mapReadingClosure(valueReadingClosure: RestXmlProtocolClientTypes.GreetingStruct.read(from:), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: true)
        return value
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `007 decode map with xmlname`() {
        val context = setupTests("Isolated/Restxml/xml-maps-xmlname.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlMapsXmlNameOutput+HttpResponseBinding.swift")
        val expectedContents = """
extension XmlMapsXmlNameOutput {

    static func httpOutput(from httpResponse: SmithyHTTPAPI.HTTPResponse) async throws -> XmlMapsXmlNameOutput {
        let data = try await httpResponse.data()
        let responseReader = try SmithyXML.Reader.from(data: data)
        let reader = responseReader
        var value = XmlMapsXmlNameOutput()
        value.myMap = try reader["myMap"].readMapIfPresent(valueReadingClosure: RestXmlProtocolClientTypes.GreetingStruct.read(from:), keyNodeInfo: "Attribute", valueNodeInfo: "Setting", isFlattened: false)
        return value
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `008 decode map with xmlname flattened`() {
        val context = setupTests("Isolated/Restxml/xml-maps-xmlname-flattened.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlMapsXmlNameFlattenedOutput+HttpResponseBinding.swift")
        val expectedContents = """
extension XmlMapsXmlNameFlattenedOutput {

    static func httpOutput(from httpResponse: SmithyHTTPAPI.HTTPResponse) async throws -> XmlMapsXmlNameFlattenedOutput {
        let data = try await httpResponse.data()
        let responseReader = try SmithyXML.Reader.from(data: data)
        let reader = responseReader
        var value = XmlMapsXmlNameFlattenedOutput()
        value.myMap = try reader["myMap"].readMapIfPresent(valueReadingClosure: RestXmlProtocolClientTypes.GreetingStruct.read(from:), keyNodeInfo: "SomeCustomKey", valueNodeInfo: "SomeCustomValue", isFlattened: true)
        return value
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `009 decode map with xmlname nested`() {
        val context = setupTests("Isolated/Restxml/xml-maps-xmlname-nested.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlMapsXmlNameNestedOutput+HttpResponseBinding.swift")
        val expectedContents = """
extension XmlMapsXmlNameNestedOutput {

    static func httpOutput(from httpResponse: SmithyHTTPAPI.HTTPResponse) async throws -> XmlMapsXmlNameNestedOutput {
        let data = try await httpResponse.data()
        let responseReader = try SmithyXML.Reader.from(data: data)
        let reader = responseReader
        var value = XmlMapsXmlNameNestedOutput()
        value.myMap = try reader["myMap"].readMapIfPresent(valueReadingClosure: SmithyReadWrite.mapReadingClosure(valueReadingClosure: RestXmlProtocolClientTypes.GreetingStruct.read(from:), keyNodeInfo: "CustomKey2", valueNodeInfo: "CustomValue2", isFlattened: false), keyNodeInfo: "CustomKey1", valueNodeInfo: "CustomValue1", isFlattened: false)
        return value
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `011 decode flattened nested map with xmlname`() {
        val context = setupTests("Isolated/Restxml/xml-maps-flattened-nested-xmlname.smithy", "aws.protocoltests.restxml#RestXml")
        val contents =
            getFileContents(context.manifest, "Sources/RestXml/models/XmlMapsFlattenedNestedXmlNameOutput+HttpResponseBinding.swift")
        val expectedContents = """
extension XmlMapsFlattenedNestedXmlNameOutput {

    static func httpOutput(from httpResponse: SmithyHTTPAPI.HTTPResponse) async throws -> XmlMapsFlattenedNestedXmlNameOutput {
        let data = try await httpResponse.data()
        let responseReader = try SmithyXML.Reader.from(data: data)
        let reader = responseReader
        var value = XmlMapsFlattenedNestedXmlNameOutput()
        value.myMap = try reader["myMap"].readMapIfPresent(valueReadingClosure: SmithyReadWrite.mapReadingClosure(valueReadingClosure: SmithyReadWrite.ReadingClosures.readString(from:), keyNodeInfo: "K", valueNodeInfo: "V", isFlattened: false), keyNodeInfo: "yek", valueNodeInfo: "eulav", isFlattened: true)
        return value
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `011 decode map with xmlnamespace`() {
        val context = setupTests("Isolated/Restxml/xml-maps-namespace.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlMapsXmlNamespaceOutput+HttpResponseBinding.swift")
        val expectedContents = """
extension XmlMapsXmlNamespaceOutput {

    static func httpOutput(from httpResponse: SmithyHTTPAPI.HTTPResponse) async throws -> XmlMapsXmlNamespaceOutput {
        let data = try await httpResponse.data()
        let responseReader = try SmithyXML.Reader.from(data: data)
        let reader = responseReader
        var value = XmlMapsXmlNamespaceOutput()
        value.myMap = try reader[.init("myMap", namespaceDef: .init(prefix: "", uri: "http://boo.com"))].readMapIfPresent(valueReadingClosure: SmithyReadWrite.ReadingClosures.readString(from:), keyNodeInfo: .init("Quality", namespaceDef: .init(prefix: "", uri: "http://doo.com")), valueNodeInfo: .init("Degree", namespaceDef: .init(prefix: "", uri: "http://eoo.com")), isFlattened: false)
        return value
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `012 decode flattened map with xmlnamespace`() {
        val context = setupTests("Isolated/Restxml/xml-maps-flattened-namespace.smithy", "aws.protocoltests.restxml#RestXml")
        val contents =
            getFileContents(context.manifest, "Sources/RestXml/models/XmlMapsFlattenedXmlNamespaceOutput+HttpResponseBinding.swift")
        val expectedContents = """
extension XmlMapsFlattenedXmlNamespaceOutput {

    static func httpOutput(from httpResponse: SmithyHTTPAPI.HTTPResponse) async throws -> XmlMapsFlattenedXmlNamespaceOutput {
        let data = try await httpResponse.data()
        let responseReader = try SmithyXML.Reader.from(data: data)
        let reader = responseReader
        var value = XmlMapsFlattenedXmlNamespaceOutput()
        value.myMap = try reader[.init("myMap", namespaceDef: .init(prefix: "", uri: "http://boo.com"))].readMapIfPresent(valueReadingClosure: SmithyReadWrite.ReadingClosures.readString(from:), keyNodeInfo: .init("Uid", namespaceDef: .init(prefix: "", uri: "http://doo.com")), valueNodeInfo: .init("Val", namespaceDef: .init(prefix: "", uri: "http://eoo.com")), isFlattened: true)
        return value
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `013 decode nested map with xmlnamespace`() {
        val context = setupTests("Isolated/Restxml/xml-maps-nested-namespace.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlMapsNestedXmlNamespaceOutput+HttpResponseBinding.swift")
        val expectedContents = """
extension XmlMapsNestedXmlNamespaceOutput {

    static func httpOutput(from httpResponse: SmithyHTTPAPI.HTTPResponse) async throws -> XmlMapsNestedXmlNamespaceOutput {
        let data = try await httpResponse.data()
        let responseReader = try SmithyXML.Reader.from(data: data)
        let reader = responseReader
        var value = XmlMapsNestedXmlNamespaceOutput()
        value.myMap = try reader[.init("myMap", namespaceDef: .init(prefix: "", uri: "http://boo.com"))].readMapIfPresent(valueReadingClosure: SmithyReadWrite.mapReadingClosure(valueReadingClosure: SmithyReadWrite.ReadingClosures.readString(from:), keyNodeInfo: .init("K", namespaceDef: .init(prefix: "", uri: "http://goo.com")), valueNodeInfo: .init("V", namespaceDef: .init(prefix: "", uri: "http://hoo.com")), isFlattened: false), keyNodeInfo: .init("yek", namespaceDef: .init(prefix: "", uri: "http://doo.com")), valueNodeInfo: .init("eulav", namespaceDef: .init(prefix: "", uri: "http://eoo.com")), isFlattened: false)
        return value
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `014 decode nested flattened map with xmlnamespace`() {
        val context = setupTests("Isolated/Restxml/xml-maps-flattened-nested-namespace.smithy", "aws.protocoltests.restxml#RestXml")
        val contents =
            getFileContents(context.manifest, "Sources/RestXml/models/XmlMapsFlattenedNestedXmlNamespaceOutput+HttpResponseBinding.swift")
        val expectedContents = """
extension XmlMapsFlattenedNestedXmlNamespaceOutput {

    static func httpOutput(from httpResponse: SmithyHTTPAPI.HTTPResponse) async throws -> XmlMapsFlattenedNestedXmlNamespaceOutput {
        let data = try await httpResponse.data()
        let responseReader = try SmithyXML.Reader.from(data: data)
        let reader = responseReader
        var value = XmlMapsFlattenedNestedXmlNamespaceOutput()
        value.myMap = try reader[.init("myMap", namespaceDef: .init(prefix: "", uri: "http://boo.com"))].readMapIfPresent(valueReadingClosure: SmithyReadWrite.mapReadingClosure(valueReadingClosure: SmithyReadWrite.ReadingClosures.readString(from:), keyNodeInfo: .init("K", namespaceDef: .init(prefix: "", uri: "http://goo.com")), valueNodeInfo: .init("V", namespaceDef: .init(prefix: "", uri: "http://hoo.com")), isFlattened: false), keyNodeInfo: .init("yek", namespaceDef: .init(prefix: "", uri: "http://doo.com")), valueNodeInfo: .init("eulav", namespaceDef: .init(prefix: "", uri: "http://eoo.com")), isFlattened: true)
        return value
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `015 decode map containing list`() {
        val context = setupTests("Isolated/Restxml/xml-maps-contain-list.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlMapsContainListOutput+HttpResponseBinding.swift")
        val expectedContents = """
extension XmlMapsContainListOutput {

    static func httpOutput(from httpResponse: SmithyHTTPAPI.HTTPResponse) async throws -> XmlMapsContainListOutput {
        let data = try await httpResponse.data()
        let responseReader = try SmithyXML.Reader.from(data: data)
        let reader = responseReader
        var value = XmlMapsContainListOutput()
        value.myMap = try reader["myMap"].readMapIfPresent(valueReadingClosure: SmithyReadWrite.listReadingClosure(memberReadingClosure: SmithyReadWrite.ReadingClosures.readString(from:), memberNodeInfo: "member", isFlattened: false), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false)
        return value
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `016 decode flattened map containing list`() {
        val context = setupTests("Isolated/Restxml/xml-maps-flattened-contain-list.smithy", "aws.protocoltests.restxml#RestXml")
        val contents =
            getFileContents(context.manifest, "Sources/RestXml/models/XmlMapsFlattenedContainListOutput+HttpResponseBinding.swift")
        val expectedContents = """
extension XmlMapsFlattenedContainListOutput {

    static func httpOutput(from httpResponse: SmithyHTTPAPI.HTTPResponse) async throws -> XmlMapsFlattenedContainListOutput {
        let data = try await httpResponse.data()
        let responseReader = try SmithyXML.Reader.from(data: data)
        let reader = responseReader
        var value = XmlMapsFlattenedContainListOutput()
        value.myMap = try reader["myMap"].readMapIfPresent(valueReadingClosure: SmithyReadWrite.listReadingClosure(memberReadingClosure: SmithyReadWrite.ReadingClosures.readString(from:), memberNodeInfo: "member", isFlattened: false), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: true)
        return value
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `017 decode map containing timestamp`() {
        val context = setupTests("Isolated/Restxml/xml-maps-timestamp.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlMapsTimestampsOutput+HttpResponseBinding.swift")
        val expectedContents = """
extension XmlMapsTimestampsOutput {

    static func httpOutput(from httpResponse: SmithyHTTPAPI.HTTPResponse) async throws -> XmlMapsTimestampsOutput {
        let data = try await httpResponse.data()
        let responseReader = try SmithyXML.Reader.from(data: data)
        let reader = responseReader
        var value = XmlMapsTimestampsOutput()
        value.timestampMap = try reader["timestampMap"].readMapIfPresent(valueReadingClosure: SmithyReadWrite.timestampReadingClosure(format: SmithyTimestamps.TimestampFormat.epochSeconds), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false)
        return value
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `018 decode flattened map containing timestamp`() {
        val context = setupTests("Isolated/Restxml/xml-maps-flattened-timestamp.smithy", "aws.protocoltests.restxml#RestXml")
        val contents =
            getFileContents(context.manifest, "Sources/RestXml/models/XmlMapsFlattenedTimestampsOutput+HttpResponseBinding.swift")
        val expectedContents = """
extension XmlMapsFlattenedTimestampsOutput {

    static func httpOutput(from httpResponse: SmithyHTTPAPI.HTTPResponse) async throws -> XmlMapsFlattenedTimestampsOutput {
        let data = try await httpResponse.data()
        let responseReader = try SmithyXML.Reader.from(data: data)
        let reader = responseReader
        var value = XmlMapsFlattenedTimestampsOutput()
        value.timestampMap = try reader["timestampMap"].readMapIfPresent(valueReadingClosure: SmithyReadWrite.timestampReadingClosure(format: SmithyTimestamps.TimestampFormat.epochSeconds), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: true)
        return value
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `019 two maps that may conflict with KeyValue`() {
        val context = setupTests("Isolated/Restxml/xml-maps-2x.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlMapsTwoOutput+HttpResponseBinding.swift")
        val expectedContents = """
extension XmlMapsTwoOutput {

    static func httpOutput(from httpResponse: SmithyHTTPAPI.HTTPResponse) async throws -> XmlMapsTwoOutput {
        let data = try await httpResponse.data()
        let responseReader = try SmithyXML.Reader.from(data: data)
        let reader = responseReader
        var value = XmlMapsTwoOutput()
        value.myMap = try reader["myMap"].readMapIfPresent(valueReadingClosure: SmithyReadWrite.ReadingClosures.readString(from:), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false)
        value.mySecondMap = try reader["mySecondMap"].readMapIfPresent(valueReadingClosure: SmithyReadWrite.ReadingClosures.readString(from:), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false)
        return value
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }
}
