/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
package software.amazon.smithy.swift.codegen

import software.amazon.smithy.codegen.core.SymbolDependency
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator

class DependencyJSONGenerator(
    val ctx: ProtocolGenerator.GenerationContext,
) {
    fun writePackageJSON(dependencies: List<SymbolDependency>) {
        ctx.delegator.useFileWriter("Dependencies.json") { writer ->
            writer.openBlock("[", "]") {
                val externalDependencies =
                    dependencies.filter { it.getProperty("url", String::class.java).isPresent }

                val dependenciesByTarget =
                    externalDependencies
                        .distinctBy { it.targetName + it.packageName }
                        .sortedBy { it.targetName }

                dependenciesByTarget.forEach { writer.write("\$S,", it.targetName) }
                writer.unwrite(",\n")
                writer.write("")
            }
        }
    }
}
