/*
 * Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License").
 * You may not use this file except in compliance with the License.
 * A copy of the License is located at
 *
 *  http://aws.amazon.com/apache2.0
 *
 * or in the "license" file accompanying this file. This file is distributed
 * on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 * express or implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */
package software.amazon.smithy.swift.codegen

import io.kotest.matchers.string.shouldContain
import org.junit.jupiter.api.Assertions
import org.junit.jupiter.api.Test
import software.amazon.smithy.build.MockManifest

class DocumentTypeGeneratorTests : TestsBase() {

    val expectedPathToJSONValueEnum = "example/models/JSONValue.swift"
    val model = createModelFromShapes()
    val manifest = MockManifest()
    val context = buildMockPluginContext(model, manifest)
    val settings: SwiftSettings = SwiftSettings.from(context.model, context.settings)

    @Test
    fun `DocumentTypeGenerator renders JSONValue enum at right location`() {

        DocumentTypeGenerator(settings, manifest).generateDocumentTypeDefinition()
        Assertions.assertTrue(manifest.hasFile(expectedPathToJSONValueEnum))
    }

    @Test
    fun `JSONValue enum generated covers all supported document subtypes`() {

        DocumentTypeGenerator(settings, manifest).generateDocumentTypeDefinition()

        val contents = manifest.getFileString(expectedPathToJSONValueEnum).get()
        val expectedEnumCases = "" +
                "public enum JSONValue {\n" +
                "    case boolean(Bool)\n" +
                "    case string(String)\n" +
                "    case array([JSONValue])\n" +
                "    case integer(Int)\n" +
                "    case float(Double)\n" +
                "    case object([String: JSONValue])\n" +
                "    case null\n" +
                "}\n"
        contents.shouldContain(expectedEnumCases)

    }

    @Test
    fun `JSONValue enum generated confirms to codable protocol`() {

        DocumentTypeGenerator(settings, manifest).generateDocumentTypeDefinition()

        val contents = manifest.getFileString(expectedPathToJSONValueEnum).get()
        val expectedConformanceToCodableProtocol = "" +
                "extension JSONValue: Codable {\n" +
                "    public init(from decoder: Decoder) throws {\n" +
                "        let container = try decoder.singleValueContainer()\n" +
                "        if let value = try? container.decode(Bool.self) {\n" +
                "            self = .boolean(value)\n" +
                "        }\n" +
                "        else if let value = try? container.decode(String.self) {\n" +
                "            self = .string(value)\n" +
                "        }\n" +
                "        else if let value = try? container.decode([JSONValue].self) {\n" +
                "            self = .array(value)\n" +
                "        }\n" +
                "        else if let value = try? container.decode(Int.self) {\n" +
                "            self = .integer(value)\n" +
                "        }\n" +
                "        else if let value = try? container.decode(Double.self) {\n" +
                "            self = .float(value)\n" +
                "        }\n" +
                "        else if let value = try? container.decode([String: JSONValue].self) {\n" +
                "            self = .object(value)\n" +
                "        }\n" +
                "        else {\n" +
                "            self = .null\n" +
                "        }\n" +
                "    }\n" +
                "    public func encode(to encoder: Encoder) throws {\n" +
                "        var container = encoder.singleValueContainer()\n" +
                "        switch self {\n" +
                "        case .boolean(let Bool):\n" +
                "            try container.encode(value)\n" +
                "        case .string(let String):\n" +
                "            try container.encode(value)\n" +
                "        case .array(let [JSONValue]):\n" +
                "            try container.encode(value)\n" +
                "        case .integer(let Int):\n" +
                "            try container.encode(value)\n" +
                "        case .float(let Double):\n" +
                "            try container.encode(value)\n" +
                "        case .object(let [String: JSONValue]):\n" +
                "            try container.encode(value)\n" +
                "        case .null:\n" +
                "            try container.encodeNil()\n" +
                "        }\n" +
                "    }\n" +
                "}\n"
        contents.shouldContain(expectedConformanceToCodableProtocol)
    }

    @Test
    fun `JSONValue enum generated confirms to ExpressibleByLiteral protocols`() {

        DocumentTypeGenerator(settings, manifest).generateDocumentTypeDefinition()

        val contents = manifest.getFileString(expectedPathToJSONValueEnum).get()
        val expectedConformanceToExpressibleByLiteralProtocol = "" +
                "extension JSONValue: ExpressibleByBooleanLiteral {\n" +
                "    public init(booleanLiteral value: Bool) {\n" +
                "        self = .boolean(value)\n" +
                "    }\n" +
                "}\n" +
                "extension JSONValue: ExpressibleByStringLiteral {\n" +
                "    public init(stringLiteral value: String) {\n" +
                "        self = .string(value)\n" +
                "    }\n" +
                "}\n" +
                "extension JSONValue: ExpressibleByArrayLiteral {\n" +
                "    public init(arrayLiteral value: [JSONValue]...) {\n" +
                "        self = .array(value)\n" +
                "    }\n" +
                "}\n" +
                "extension JSONValue: ExpressibleByIntegerLiteral {\n" +
                "    public init(integerLiteral value: Int) {\n" +
                "        self = .integer(value)\n" +
                "    }\n" +
                "}\n" +
                "extension JSONValue: ExpressibleByFloatLiteral {\n" +
                "    public init(floatLiteral value: Double) {\n" +
                "        self = .float(value)\n" +
                "    }\n" +
                "}\n" +
                "extension JSONValue: ExpressibleByDictionaryLiteral {\n" +
                "    public init(dictionaryLiteral elements: (String, JSONValue)...) {\n" +
                "        let dictionary = elements.reduce([String: JSONValue]()) { acc, curr in\n" +
                "            var newValue = acc\n" +
                "            newValue[curr.0] = curr.1\n" +
                "            return newValue\n" +
                "        }\n" +
                "        self = .object(dictionary)\n" +
                "    }\n" +
                "}\n" +
                "extension JSONValue: ExpressibleByNilLiteral {\n" +
                "    public init(nilLiteral: ()) {\n" +
                "        self = .null\n" +
                "    }\n" +
                "}\n"
        contents.shouldContain(expectedConformanceToExpressibleByLiteralProtocol)
    }

    @Test
    fun `JSONValue enum generated supports subscript based indexing`() {

        DocumentTypeGenerator(settings, manifest).generateDocumentTypeDefinition()

        val contents = manifest.getFileString(expectedPathToJSONValueEnum).get()
        val expectedExtensionForSubscriptBasedIndexing = "" +
                "public extension JSONValue {\n" +
                "    subscript(_ key: String) -> JSONValue? {\n" +
                "        guard case .object(let object) = self else {\n" +
                "            return nil\n" +
                "        }\n" +
                "        return object[key]\n" +
                "    }\n" +
                "    subscript(_ key: Int) -> JSONValue? {\n" +
                "        switch self {\n" +
                "        case .array(let array):\n" +
                "            return array[key]\n" +
                "        case .object(let object):\n" +
                "            return object[\"\\(key)\"]\n" +
                "        default:\n" +
                "            return nil\n" +
                "        }\n" +
                "    }\n" +
                "}\n"
        contents.shouldContain(expectedExtensionForSubscriptBasedIndexing)
    }
}

