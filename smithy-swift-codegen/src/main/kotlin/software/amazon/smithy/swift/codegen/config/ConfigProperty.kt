/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.config

import software.amazon.smithy.codegen.core.Symbol
data class ConfigProperty(
    val name: String,
    val type: Symbol,
    val default: DefaultProvider? = null
) {
    constructor(
        name: String,
        type: Symbol,
        default: String,
        isThrowable: Boolean = false,
        isAsync: Boolean = false
    ) : this(name, type, DefaultProvider(default, isThrowable, isAsync))

    val isOptional: Boolean = type.name.endsWith('?')

    fun toOptionalType(): String {
        return if (isOptional) type.name else "${type.name}?"
    }

    init {
        if (!this.isOptional && default == null)
            throw RuntimeException("Non-optional client config property must have a default value")
    }
}
