/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 */

package software.amazon.smithy.swift.codegen.lang

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.SwiftWriter

/**
 * Representation of a Swift function parameter.
 */
sealed class FunctionParameter(val name: String, val type: Symbol) {

    /**
     * Function parameter with no label, i.e. `_ foo: String`
     */
    class NoLabel(name: String, type: Symbol) : FunctionParameter(name, type)

    /**
     * Function parameter with the default label, i.e. `foo: String`
     */
    class DefaultLabel(val label: String, type: Symbol) : FunctionParameter(label, type)

    /**
     * Function parameter with a custom label, i.e. `foo bar: String`
     */
    class CustomLabel(val label: String, name: String, type: Symbol) : FunctionParameter(name, type)

    /**
     * Creates a string representation of this function parameter.
     */
    fun rendered(writer: SwiftWriter): String = when (this) {
        is NoLabel -> writer.format("_ $name: \$N", type)
        is DefaultLabel -> writer.format("$label: \$N", type)
        is CustomLabel -> writer.format("$label $name: \$N", type)
    }
}
