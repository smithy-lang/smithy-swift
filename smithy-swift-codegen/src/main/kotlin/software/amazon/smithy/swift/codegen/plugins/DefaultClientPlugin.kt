/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration.plugins

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.integration.Plugin
import software.amazon.smithy.swift.codegen.model.buildSymbol
import software.amazon.smithy.swift.codegen.swiftmodules.ClientRuntimeTypes

internal class DefaultClientPlugin : Plugin {
    override val className: Symbol = ClientRuntimeTypes.Core.DefaultClientPlugin

    override val isDefault: Boolean
        get() = true
}
