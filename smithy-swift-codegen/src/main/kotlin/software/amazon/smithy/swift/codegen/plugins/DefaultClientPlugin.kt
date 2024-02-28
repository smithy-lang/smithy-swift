/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration.plugins

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.integration.Plugin
import software.amazon.smithy.swift.codegen.model.buildSymbol

internal class DefaultClientPlugin : Plugin {
    override val className: Symbol
        get() = buildSymbol {
            this.name = "DefaultClientPlugin"
            this.namespace = SwiftDependency.CLIENT_RUNTIME.target
            dependency(SwiftDependency.CLIENT_RUNTIME)
        }
    override val isDefault: Boolean
        get() = true
}
