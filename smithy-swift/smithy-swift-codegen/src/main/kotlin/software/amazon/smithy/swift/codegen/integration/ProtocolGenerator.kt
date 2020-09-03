/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
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
package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.codegen.core.CodegenException
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.ServiceShape
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.SwiftDelegator
import software.amazon.smithy.swift.codegen.SwiftSettings
import software.amazon.smithy.utils.CaseUtils

/**
 * Smithy protocol code generator(s)
 */
interface ProtocolGenerator {
    companion object {
        /**
         * Sanitizes the name of the protocol so it can be used as a symbol.
         *
         * For example, the default implementation converts '.' to '_' and converts '-'
         * to become camelCase separated words. `aws.rest-json-1.1` becomes `AWSRestJson1_1`
         *
         * @param name Name of the protocol to sanitize
         * @return sanitized protocol name
         */
        fun getSanitizedName(name: String): String {
            var replacedString = name
            replacedString = replacedString.replace("^aws.".toRegex(), "AWS-")
            replacedString = replacedString.replace(".", "_")
            replacedString = CaseUtils.toCamelCase(replacedString, true, '-')
            return replacedString.replace("^Aws".toRegex(), "AWS")
        }

        fun getFormattedDateString(tsFormat: TimestampFormatTrait.Format, memberName: String, isOptional: Boolean = false): String {
            val terminator = if (isOptional) "?" else ""
            return when (tsFormat) {
                TimestampFormatTrait.Format.EPOCH_SECONDS -> "${memberName}${terminator}.timeIntervalSince1970"
                TimestampFormatTrait.Format.DATE_TIME -> "${memberName}${terminator}.iso8601FractionalSecondsString()"
                TimestampFormatTrait.Format.HTTP_DATE -> "${memberName}${terminator}.rfc5322String()"
                else -> throw CodegenException("unknown timestamp format: $tsFormat")
            }
        }
    }

    /**
     * Get the supported protocol [ShapeId]
     * e.g. `software.amazon.smithy.aws.traits.protocols.RestJson1Trait.ID`
     */
    val protocol: ShapeId

    /**
     * Get the name of the protocl
     */
    val protocolName: String
        get() {
            var prefix = protocol.namespace
            val idx = prefix.indexOf('.')
            if (idx != -1) {
                prefix = prefix.substring(0, idx)
            }
            return CaseUtils.toCamelCase(prefix) + getSanitizedName(protocol.name)
        }

    /**
     * Generate serializers required by the protocol
     */
    fun generateSerializers(ctx: GenerationContext)

    /**
     * Generate deserializers required by the protocol
     */
    fun generateDeserializers(ctx: GenerationContext)

    /**
     * Generate unit tests for the protocol
     */
    fun generateProtocolUnitTests(ctx: GenerationContext)

    /**
     * Generate an actual client implementation of the service interface
     */
    fun generateProtocolClient(ctx: GenerationContext)

    /**
     * Context object used for service serialization and deserialization
     */
    data class GenerationContext(
        val settings: SwiftSettings,
        val model: Model,
        val service: ServiceShape,
        val symbolProvider: SymbolProvider,
        val integrations: List<SwiftIntegration>,
        val protocol: ShapeId,
        val delegator: SwiftDelegator
    )
}
