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

import software.amazon.smithy.build.FileManifest
import software.amazon.smithy.utils.CaseUtils


/**
 * Generates JSONValue enum to represent the Document Type in Smithy
 */
class DocumentTypeGenerator(
    private val settings: SwiftSettings,
    private val manifest: FileManifest
) {
    val writer: SwiftWriter = SwiftWriter(settings.moduleName)

    /**
     * A Map of enum cases and associated value types for JSONValue enum
     */
    val supportedSubTypes: HashMap<String, String> by lazy { getSupportedSubTypesMap() }

    fun generateDocumentTypeDefinition() {
        // Generate enum case definitions
        generateEnumCases()

        // Generate Extension to confirm to Codable Protocol
        generateCodableProtocolExtension()

        // Generate Extensions to initialize enum with literals
        generateExpressibleByLiteralExtensions()

        // Generate Extension to support subscript based indexing for array, dictionary
        generateExtensionForSubscriptBasedIndexing()

        manifest.writeFile("${settings.moduleName}/models/JSONValue.swift", writer.toString())
    }

    private fun getSupportedSubTypesMap(): HashMap<String, String> {
        val subTypesAndTheirSwiftTargets = hashMapOf<String, String>()

        subTypesAndTheirSwiftTargets["array"] = "[JSONValue]"
        subTypesAndTheirSwiftTargets["boolean"] = "Bool"
        subTypesAndTheirSwiftTargets["integer"] = "Int"
        subTypesAndTheirSwiftTargets["float"] = "Double"
        subTypesAndTheirSwiftTargets["object"] = "[String: JSONValue]"
        subTypesAndTheirSwiftTargets["string"] = "String"

        return subTypesAndTheirSwiftTargets
    }

    fun generateEnumCases() {
        writer.openBlock("public enum JSONValue {", "}") {
            supportedSubTypes.forEach { (key, value) -> writer.write("case $key($value)") }
            writer.write("case null")
        }
    }

    fun generateCodableProtocolExtension() {
        writer.openBlock("extension JSONValue: Codable {", "}") {

            // Generate custom deserializer
            writer.openBlock("public init(from decoder: Decoder) throws {", "}") {
                writer.write("let container = try decoder.singleValueContainer()")
                var isFirstEntry = true
                for ((key, value) in supportedSubTypes) {
                    writer.openBlock(
                        "${if (isFirstEntry) "if" else "else if"} let value = try? container.decode($value.self) {",
                        "}"
                    ) {
                        writer.write("self = .$key(value)")
                    }
                    isFirstEntry = false
                }
                writer.openBlock("else {", "}") {
                    writer.write("self = .null")
                }
            }

            // Generate custom serializer
            writer.openBlock("public func encode(to encoder: Encoder) throws {", "}") {
                writer.write("var container = encoder.singleValueContainer()")
                writer.write("switch self {")
                supportedSubTypes.forEach { (key, value) ->
                    writer.write("case .$key(let $value):")
                    writer.write("    try container.encode(value)")
                }
                writer.write("case .null:")
                writer.write("    try container.encodeNil()")
                writer.write("}")
            }
        }
    }

    fun generateExpressibleByLiteralExtensions() {
        supportedSubTypes.forEach { (key, value) ->
            if (key == "object"){
                writer.openBlock("extension JSONValue: ExpressibleByDictionaryLiteral {", "}") {
                    writer.openBlock("public init(dictionaryLiteral elements: (String, JSONValue)...) {", "}") {
                        writer.openBlock("let dictionary = elements.reduce([String: JSONValue]()) { acc, curr in", "}") {
                            writer.write("var newValue = acc")
                            writer.write("newValue[curr.0] = curr.1")
                            writer.write("return newValue")
                        }
                        writer.write("self = .object(dictionary)")
                    }
                }
            }
            else {
                val associatedValueType = if (key == "array") "$value..." else value
                writer.openBlock("extension JSONValue: ExpressibleBy${CaseUtils.toPascalCase(key)}Literal {", "}") {
                    writer.openBlock("public init(${key}Literal value: $associatedValueType) {", "}") {
                        writer.write("self = .$key(value)")
                    }
                }
            }
        }
        writer.openBlock("extension JSONValue: ExpressibleByNilLiteral {", "}") {
            writer.openBlock("public init(nilLiteral: ()) {", "}") {
                writer.write("self = .null")
            }
        }
    }

    fun generateExtensionForSubscriptBasedIndexing() {
        writer.openBlock("public extension JSONValue {", "}") {

            writer.openBlock("subscript(_ key: String) -> JSONValue? {", "}") {
                writer.openBlock("guard case .object(let object) = self else {", "}") {
                    writer.write("return nil")
                }
                writer.write("return object[key]")
            }

            writer.openBlock("subscript(_ key: Int) -> JSONValue? {", "}") {
                writer.write("switch self {")
                writer.write("case .array(let array):")
                writer.write("    return array[key]")
                writer.write("case .object(let object):")
                writer.write("    return object[\"\\(key)\"]")
                writer.write("default:")
                writer.write("    return nil")
                writer.write("}")
            }
        }
    }

}