/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 */

package software.amazon.smithy.swift.codegen.lang

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.SwiftWriter
import java.util.function.Consumer

/**
 * Representation of a Swift function.
 */
data class Function(
    val name: String,
    val renderBody: Consumer<SwiftWriter>,
    val parameters: List<FunctionParameter> = emptyList(),
    val returnType: Symbol? = null,
    val accessModifier: AccessModifier = AccessModifier.Public,
    val isAsync: Boolean = false,
    val isThrowing: Boolean = false,
    val isMutating: Boolean = false,
) {
    /**
     * Render this function using the given writer.
     */
    fun render(writer: SwiftWriter) {
        val renderedMutating = "mutating ".takeIf { isMutating } ?: ""
        val renderedParameters = parameters.joinToString(", ") { it.rendered(writer) }
        val renderedAsync = if (isAsync) "async " else ""
        val renderedThrows = if (isThrowing) "throws " else ""
        val renderedReturnType = returnType?.let { writer.format("-> \$N ", it) } ?: ""
        writer.openBlock(
            "\$L\$Lfunc \$L(\$L) \$L$renderedThrows$renderedReturnType{",
            "}",
            accessModifier.renderedRightPad(),
            renderedMutating,
            name,
            renderedParameters,
            renderedAsync,
        ) {
            renderBody.accept(writer)
        }
    }
}
