/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
package software.amazon.smithy.swift.codegen

import software.amazon.smithy.codegen.core.SymbolDependency
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import kotlin.jvm.optionals.getOrNull

class PackageManifestGenerator(
    val ctx: ProtocolGenerator.GenerationContext,
) {
    fun writePackageManifest(dependencies: List<SymbolDependency>) {
        ctx.delegator.useFileWriter("Package.swift") { writer ->
            writer.write("// swift-tools-version: \$L", ctx.settings.swiftVersion)
            writer.write("")
            writer.write("import PackageDescription")
            writer.write("")

            writer.openBlock("let package = Package(", ")") {
                writer.write("name: \$S,", ctx.settings.moduleName)

                writer.openBlock("platforms: [", "],") {
                    writer.write(".macOS(.v12), .iOS(.v13)")
                }

                writer.openBlock("products: [", "],") {
                    writer.write(".library(name: \$S, targets: [\$S])", ctx.settings.moduleName, ctx.settings.moduleName)
                }

                val externalDependencies =
                    dependencies.filter { it.getProperty("url", String::class.java).getOrNull() != null }

                val dependenciesByURL =
                    externalDependencies
                        .distinctBy { it.getProperty("url", String::class.java).getOrNull() }
                        .sortedBy { it.targetName() }

                writer.openBlock("dependencies: [", "],") {
                    dependenciesByURL.forEach { writePackageDependency(writer, it) }
                }

                val dependenciesByTarget =
                    externalDependencies
                        .distinctBy { it.targetName() + it.packageName }
                        .sortedBy { it.targetName() }

                writer.openBlock("targets: [", "]") {
                    writer.openBlock(".target(", "),") {
                        writer.write("name: \$S,", ctx.settings.moduleName)
                        writer.openBlock("dependencies: [", "]") {
                            dependenciesByTarget.forEach { writeTargetDependency(writer, it) }
                        }
                    }
                    writer.openBlock(".testTarget(", ")") {
                        writer.write("name: \$S,", ctx.settings.testModuleName)
                        writer.openBlock("dependencies: [", "]") {
                            writer.write("\$S,", ctx.settings.moduleName)
                            SwiftDependency.SMITHY_TEST_UTIL.dependencies.forEach { writeTargetDependency(writer, it) }
                        }
                    }
                }
            }
        }
    }

    private fun writePackageDependency(
        writer: SwiftWriter,
        dependency: SymbolDependency,
    ) {
        writer.openBlock(".package(", "),") {
            val url = dependency.getProperty("url", String::class.java).get()
            writer.write("url: \$S,", url)
            writer.write("exact: \$S", dependency.version)
        }
    }

    private fun writeTargetDependency(
        writer: SwiftWriter,
        dependency: SymbolDependency,
    ) {
        writer.openBlock(".product(", "),") {
            writer.write("name: \$S,", dependency.targetName())
            writer.write("package: \$S", dependency.packageName)
        }
    }
}

private fun SymbolDependency.targetName(): String = expectProperty("target", String::class.java)
