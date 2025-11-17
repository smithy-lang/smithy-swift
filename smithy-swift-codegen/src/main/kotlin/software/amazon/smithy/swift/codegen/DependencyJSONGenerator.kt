/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
package software.amazon.smithy.swift.codegen

import software.amazon.smithy.aws.traits.ServiceTrait
import software.amazon.smithy.codegen.core.SymbolDependency
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.model.expectTrait
import software.amazon.smithy.swift.codegen.model.getTrait

class DependencyJSONGenerator(
    val ctx: ProtocolGenerator.GenerationContext,
) {
    fun writePackageJSON(dependencies: List<SymbolDependency>) {
        ctx.delegator.useFileWriter("Dependencies.json") { writer ->
            writer.setIndentText("  ") // two spaces
            writer.openBlock("{", "}") {
                // Write the path to the model as "modelPath" if ServiceTrait exists.
                ctx.service.getTrait<ServiceTrait>()?.let {
                    val modelFileName = it
                        .sdkId
                        .lowercase()
                        .replace(",", "")
                        .replace(" ", "-")
                    writer.write("\"modelPath\": \$S,", "codegen/sdk-codegen/aws-models/$modelFileName.json")
                }

                // Write the dependencies as an array of strings to key "dependencies".
                writer.openBlock("\"dependencies\": [", "]") {
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
}
