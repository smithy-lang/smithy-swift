/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.config

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.lang.AccessModifier
import software.amazon.smithy.swift.codegen.model.isOptional

data class ConfigProperty(
    val name: String,
    val type: Symbol,
    val default: DefaultProvider? = null,
    val accessModifier: AccessModifier = AccessModifier.Public,
) {

    constructor(
        name: String,
        type: Symbol,
        default: (SwiftWriter) -> String,
        isThrowable: Boolean = false,
        isAsync: Boolean = false,
        accessModifier: AccessModifier = AccessModifier.Public
    ) : this(name, type, DefaultProvider(default, isThrowable, isAsync), accessModifier)

    init {
        if (!type.isOptional() && default == null)
            throw RuntimeException("Non-optional client config property must have a default value")
    }

    fun render(writer: SwiftWriter) {
        writer.write("${accessModifier.renderedRightPad()}var \$L: \$N", name, type)
    }
}
