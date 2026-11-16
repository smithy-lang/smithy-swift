/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.UnionShape
import software.amazon.smithy.model.traits.SensitiveTrait
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.CustomDebugStringConvertibleGenerator.Companion.REDACT_STRING
import software.amazon.smithy.swift.codegen.integration.CustomDebugStringConvertibleGenerator.Companion.isSensitive
import software.amazon.smithy.swift.codegen.model.eventStreamEvents
import software.amazon.smithy.swift.codegen.model.hasTrait
import software.amazon.smithy.swift.codegen.swiftmodules.SwiftTypes

/**
 * Renders a `CustomDebugStringConvertible` conformance for a union (Swift enum)
 * that redacts the associated value of every variant holding sensitive content.
 */
class UnionCustomDebugStringConvertibleGenerator(
    private val symbolProvider: SymbolProvider,
    private val writer: SwiftWriter,
    private val shape: UnionShape,
    private val model: Model,
) {
    companion object {
        fun MemberShape.isSensitiveVariant(model: Model): Boolean = hasTrait<SensitiveTrait>() || isSensitive(model)

        fun UnionShape.needsRedactingDebugDescription(model: Model): Boolean =
            hasTrait<SensitiveTrait>() || eventStreamEvents(model).any { it.isSensitiveVariant(model) }
    }

    private val unionSymbol: Symbol by lazy {
        symbolProvider.toSymbol(shape)
    }

    fun render() {
        writer.openBlock("extension \$N: \$N {", "}", unionSymbol, SwiftTypes.Protocols.CustomDebugStringConvertible) {
            writer.openBlock("public var debugDescription: \$N {", "}", SwiftTypes.String) {
                if (shape.hasTrait<SensitiveTrait>()) {
                    writer.write("\"$REDACT_STRING\"")
                } else {
                    renderSwitch()
                }
            }
        }
    }

    private fun renderSwitch() {
        val typeName = unionSymbol.name
        writer.write("switch self {")
        shape.eventStreamEvents(model).forEach { member ->
            val caseName = symbolProvider.toMemberName(member)
            val displayName = caseName.removeSurrounding("`")
            if (member.isSensitiveVariant(model)) {
                writer.write("case .\$L:", caseName)
                writer.indent {
                    writer.write("return \"\$L.\$L(\\\"$REDACT_STRING\\\")\"", typeName, displayName)
                }
            } else {
                renderDescribedCase(typeName, caseName, displayName)
            }
        }
        renderDescribedCase(typeName, "sdkUnknown", "sdkUnknown")
        writer.write("}")
    }

    private fun renderDescribedCase(
        typeName: String,
        caseName: String,
        displayName: String,
    ) {
        writer.write("case .\$L(let value):", caseName)
        writer.indent {
            writer.write("return \"\$L.\$L(\\(\$N(describing: value)))\"", typeName, displayName, SwiftTypes.String)
        }
    }
}
