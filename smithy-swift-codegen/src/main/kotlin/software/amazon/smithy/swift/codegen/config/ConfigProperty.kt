/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.config

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.model.isOptional

data class ConfigProperty(
    val name: String,
    val type: Symbol,
    val default: DefaultProvider? = null
) {

    constructor(
        name: String,
        type: Symbol,
        default: (SwiftWriter) -> String,
        isThrowable: Boolean = false,
        isAsync: Boolean = false
    ) : this(name, type, DefaultProvider(default, isThrowable, isAsync))

    init {
        if (!type.isOptional() && default == null)
            throw RuntimeException("Non-optional client config property must have a default value")
    }
}
