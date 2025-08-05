/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
package software.amazon.smithy.swift.codegen

import software.amazon.smithy.codegen.core.SymbolDependency
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import kotlin.jvm.optionals.getOrNull

val SERVICE_CLIENT_JSON_NAME = "Dependencies.json"

class ServiceClientJSONGenerator(
    val ctx: ProtocolGenerator.GenerationContext,
) {
    fun writePackageJSON(dependencies: List<SymbolDependency>) {
        ctx.delegator.useFileWriter(SERVICE_CLIENT_JSON_NAME) { writer ->
            writer.openBlock("[", "]") {
                val externalDependencies =
                    dependencies
                        .filter {
                            it.getProperty("url", String::class.java).getOrNull() != null ||
                                it.getProperty("scope", String::class.java).getOrNull() != null
                        }

                val dependenciesByTarget =
                    externalDependencies
                        .distinctBy { it.targetName() + it.packageName }
                        .sortedBy { it.targetName() }

                dependenciesByTarget.forEach { writer.write("\$S,", it.targetName()) }
                writer.unwrite(",\n")
                writer.write("")
            }
        }
    }
}

private fun SymbolDependency.targetName(): String = expectProperty("target", String::class.java)
