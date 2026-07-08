/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
package software.amazon.smithy.swift.codegen

import software.amazon.smithy.codegen.core.SymbolDependency
import software.amazon.smithy.swift.codegen.core.GenerationContext
import software.amazon.smithy.swift.codegen.utils.SDKFileUtils

class PackageManifestGenerator(
    val ctx: GenerationContext,
) {
    fun writePackageManifest(dependencies: List<SymbolDependency>) {
        val filename = SDKFileUtils(ctx.settings).rootDirFilePath("Package")
        ctx.writerDelegator().useFileWriter(filename) { writer ->
            writer.write("// swift-tools-version: \$L", ctx.settings.swiftVersion)
            writer.write("")
            writer.write("import PackageDescription")
            writer.write("")

            writer.openBlock("let package = Package(", ")") {
                writer.write("name: \$S,", ctx.settings.moduleName)

                writer.openBlock("platforms: [", "],") {
                    writer.write(".macOS(.v12), .iOS(.v13), .tvOS(.v13), .watchOS(.v6)")
                }

                writer.openBlock("products: [", "],") {
                    writer.write(".library(name: \$S, targets: [\$S])", ctx.settings.moduleName, ctx.settings.moduleName)
                }

                val externalDependencies =
                    dependencies.filter { it.getProperty("url", String::class.java).isPresent }

                val dependenciesByURL =
                    externalDependencies
                        .distinctBy { it.expectProperty("url", String::class.java) }
                        .sortedBy { it.targetName }

                writer.openBlock("dependencies: [", "],") {
                    dependenciesByURL.forEach { writePackageDependency(writer, it) }
                }

                val dependenciesByTarget =
                    externalDependencies
                        .filter { it.targetName != "SmithyTestUtil" }
                        .distinctBy { it.targetName + it.packageName }
                        .sortedBy { it.targetName }

                writer.openBlock("targets: [", "]") {
                    writer.openBlock(".target(", "),") {
                        writer.write("name: \$S,", ctx.settings.moduleName)
                        writer.openBlock("dependencies: [", "],") {
                            dependenciesByTarget.forEach { writeTargetDependency(writer, it) }
                        }
                        writer.openBlock("plugins: [", "]") {
                            writer.openBlock(".plugin(", "),") {
                                writer.write("name: \$S,", "SmithyCodeGeneratorPlugin")
                                writer.write("package: \$S", "smithy-swift")
                            }
                        }
                    }
                    if (externalDependencies.any { it.targetName == "SmithyTestUtil" }) {
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
    }

    private fun writePackageDependency(
        writer: SwiftWriter,
        dependency: SymbolDependency,
    ) {
        if (ctx.settings.localDevelopment) {
            // Use local smithy-swift for local development
            writer.write(".package(path: \$S),", "../../../../../../../../smithy-swift")
        } else {
            // For other generated clients, use stable, published smithy-swift
            val url = dependency.expectProperty("url", String::class.java)
            writer.write(".package(url: \$S, exact: \$S),", url, dependency.version)
        }
    }

    private fun writeTargetDependency(
        writer: SwiftWriter,
        dependency: SymbolDependency,
    ) {
        writer.openBlock(".product(", "),") {
            writer.write("name: \$S,", dependency.targetName)
            writer.write("package: \$S", dependency.packageName)
        }
    }
}

val SymbolDependency.targetName: String
    get() = expectProperty("target", String::class.java)
