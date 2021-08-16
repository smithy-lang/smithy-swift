/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen

import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.swift.codegen.model.nestedNamespaceType

class ServiceNamespaceGenerator(
    private val settings: SwiftSettings,
    private val model: Model,
    private val symbolProvider: SymbolProvider,
    private val writer: SwiftWriter,
) {

    fun render() {
        val service = settings.getService(model)
        writer.write("public enum ${service.nestedNamespaceType(symbolProvider)} {}")
    }
}
