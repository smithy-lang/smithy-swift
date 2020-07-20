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

import java.util.logging.Logger
import kotlin.streams.toList
import software.amazon.smithy.codegen.core.CodegenException
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.knowledge.ServiceIndex
import software.amazon.smithy.model.node.ObjectNode
import software.amazon.smithy.model.node.StringNode
import software.amazon.smithy.model.shapes.ServiceShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.ShapeId

private const val SERVICE = "service"
private const val MODULE_NAME = "module"
private const val MODULE_DESCRIPTION = "moduleDescription"
private const val MODULE_VERSION = "moduleVersion"
private const val GIT_REPO = "gitRepo"
private const val HOMEPAGE = "homepage"
private const val AUTHOR = "author"
private const val SWIFT_VERSION = "swiftVersion"

class SwiftSettings(
    val service: ShapeId,
    val moduleName: String,
    val moduleVersion: String,
    val moduleDescription: String,
    val author: String,
    val homepage: String,
    val gitRepo: String,
    val swiftVersion: String
) {

    companion object {

        private val LOGGER: Logger = Logger.getLogger(SwiftSettings::class.java.name)
        val reservedKeywords: List<String> = getSwiftReservedKeywords()

        /**
         * Create settings from a configuration object node.
         *
         * @param model Model to infer the service from (if not explicitly set in config)
         * @param config Config object to load
         * @throws software.amazon.smithy.model.node.ExpectationNotMetException
         * @return Returns the extracted settings
         */
        fun from(model: Model, config: ObjectNode): SwiftSettings {
            config.warnIfAdditionalProperties(arrayListOf(SERVICE, MODULE_NAME, MODULE_DESCRIPTION, MODULE_VERSION, AUTHOR, HOMEPAGE, GIT_REPO, SWIFT_VERSION))

            val service = config.getStringMember(SERVICE)
                .map(StringNode::expectShapeId)
                .orElseGet { inferService(model) }

            val moduleName = config.expectStringMember(MODULE_NAME).value
            val version = config.expectStringMember(MODULE_VERSION).value
            val desc = config.getStringMemberOrDefault(MODULE_DESCRIPTION, "$moduleName client")
            val homepage = config.expectStringMember(HOMEPAGE).value
            val author = config.expectStringMember(AUTHOR).value
            val gitRepo = config.expectStringMember(GIT_REPO).value
            val swiftVersion = config.expectStringMember(SWIFT_VERSION).value
            return SwiftSettings(service, moduleName, version, desc, author, homepage, gitRepo, swiftVersion)
        }

        // infer the service to generate from a model
        private fun inferService(model: Model): ShapeId {
            val services = model.shapes(ServiceShape::class.java)
                .map(Shape::getId)
                .sorted()
                .toList()

            when {
                services.isEmpty() -> {
                    throw CodegenException(
                        "Cannot infer a service to generate because the model does not " +
                                "contain any service shapes"
                    )
                }
                services.size > 1 -> {
                    throw CodegenException(
                        "Cannot infer service to generate because the model contains " +
                                "multiple service shapes: " + services
                    )
                }
                else -> {
                    val service = services[0]
                    LOGGER.info("Inferring service to generate as: $service")
                    return service
                }
            }
        }

        /**
         * Get Reserved Keywords in Swift as a list
         */
        private fun getSwiftReservedKeywords(): List<String> {
            var reservedWords = "Any\n" +
                    "#available\n" +
                    "associatedtype\n" +
                    "associativity\n" +
                    "as\n" +
                    "break\n" +
                    "case\n" +
                    "catch\n" +
                    "class\n" +
                    "#colorLiteral\n" +
                    "#column\n" +
                    "continue\n" +
                    "convenience\n" +
                    "deinit\n" +
                    "default\n" +
                    "defer\n" +
                    "didSet\n" +
                    "do\n" +
                    "dynamic\n" +
                    "enum\n" +
                    "extension\n" +
                    "else\n" +
                    "#else\n" +
                    "#elseif\n" +
                    "#endif\n" +
                    "#error\n" +
                    "fallthrough\n" +
                    "false\n" +
                    "#file\n" +
                    "#fileLiteral\n" +
                    "fileprivate\n" +
                    "final\n" +
                    "for\n" +
                    "func\n" +
                    "#function\n" +
                    "get\n" +
                    "guard\n" +
                    "indirect\n" +
                    "infix\n" +
                    "if\n" +
                    "#if\n" +
                    "#imageLiteral\n" +
                    "in\n" +
                    "is\n" +
                    "import\n" +
                    "init\n" +
                    "inout\n" +
                    "internal\n" +
                    "lazy\n" +
                    "left\n" +
                    "let\n" +
                    "#line\n" +
                    "mutating\n" +
                    "none\n" +
                    "nonmutating\n" +
                    "nil\n" +
                    "open\n" +
                    "operator\n" +
                    "optional\n" +
                    "override\n" +
                    "postfix\n" +
                    "private\n" +
                    "protocol\n" +
                    "Protocol\n" +
                    "public\n" +
                    "repeat\n" +
                    "rethrows\n" +
                    "return\n" +
                    "required\n" +
                    "right\n" +
                    "#selector\n" +
                    "self\n" +
                    "Self\n" +
                    "set\n" +
                    "#sourceLocation\n" +
                    "super\n" +
                    "static\n" +
                    "struct\n" +
                    "subscript\n" +
                    "switch\n" +
                    "this\n" +
                    "throw\n" +
                    "throws\n" +
                    "true\n" +
                    "try\n" +
                    "Type\n" +
                    "typealias\n" +
                    "unowned\n" +
                    "var\n" +
                    "#warning\n" +
                    "weak\n" +
                    "willSet\n" +
                    "where\n" +
                    "while"
            reservedWords = reservedWords.replace("\n", ",")
            print(reservedWords)
            return reservedWords.split(",").map { it.trim() }
        }
    }

    /**
     * Gets the corresponding [ServiceShape] from a model.
     *
     * @param model Model to search for the service shape by ID.
     * @return Returns the found `Service`.
     * @throws NullPointerException if the service has not been set.
     * @throws CodegenException if the service is invalid or not found.
     */
    fun getService(model: Model): ServiceShape {
        return model
            .getShape(this.service)
            .orElseThrow { CodegenException("Service shape not found: " + this.service) }
            .asServiceShape()
            .orElseThrow { CodegenException("Shape is not a Service: " + this.service) }
    }

    /**
     * Resolves the highest priority protocol from a service shape that is
     * supported by the generator.
     *
     * @param serviceIndex Service index containing the support
     * @param service Service to get the protocols from if "protocols" is not set.
     * @param supportedProtocolTraits The set of protocol traits supported by the generator.
     * @return Returns the resolved protocol name.
     * @throws UnresolvableProtocolException if no protocol could be resolved.
     */
    fun resolveServiceProtocol(
        serviceIndex: ServiceIndex,
        service: ServiceShape,
        supportedProtocolTraits: Set<ShapeId>
    ): ShapeId {
        print("inside resolve service protocol")
        val resolvedProtocols: Set<ShapeId> = serviceIndex.getProtocols(service).keys
        val protocol = resolvedProtocols.firstOrNull(supportedProtocolTraits::contains)
        return protocol ?: throw UnresolvableProtocolException(
            "The ${service.id} service supports the following unsupported protocols $resolvedProtocols. " +
                    "The following protocol generators were found on the class path: $supportedProtocolTraits")
    }
}

class UnresolvableProtocolException(message: String) : CodegenException(message)
