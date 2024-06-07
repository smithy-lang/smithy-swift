/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
package software.amazon.smithy.swift.codegen

import software.amazon.smithy.codegen.core.SymbolDependency
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator

class PackageManifestGenerator(val ctx: ProtocolGenerator.GenerationContext) {

    fun writePackageManifest(dependencies: List<SymbolDependency>) {
        ctx.delegator.useFileWriter("Package.swift") { writer ->
            writer.write("// swift-tools-version:\$L", ctx.settings.swiftVersion)
            writer.write("")
            writer.write("import PackageDescription")
            writer.write("")

            writer.openBlock("let package = Package(", ")") {
                writer.write("name: \$S,", ctx.settings.moduleName)

                writer.openBlock("platforms: [", "],") {
                    writer.write(".macOS(.v10_15), .iOS(.v13)")
                }

                writer.openBlock("products: [", "],") {
                    writer.write(".library(name: \$S, targets: [\$S])", ctx.settings.moduleName, ctx.settings.moduleName)
                }

                val distinctDependencies = dependencies.distinctBy { it.expectProperty("target", String::class.java) + it.packageName }

                writer.openBlock("dependencies: [", "],") {
                    distinctDependencies.forEach { dependency ->
                        writer.openBlock(".package(", "),") {
                            val dependencyURL = dependency.expectProperty("url", String::class.java)
                            writer.write("url: \$S,", dependencyURL)
                            writer.write("from: \$S", dependency.version)
                        }
                    }
                }

                writer.openBlock("targets: [", "]") {
                    writer.openBlock(".target(", "),") {
                        writer.write("name: \$S,", ctx.settings.moduleName)
                        writer.openBlock("dependencies: [", "],") {
                            for (dependency in distinctDependencies) {
                                writer.openBlock(".product(", "),") {
                                    val target = dependency.expectProperty("target", String::class.java)
                                    writer.write("name: \$S,", target)
                                    writer.write("package: \$S", dependency.packageName)
                                }
                            }
                        }
                        writer.write("path: \"./\$L\"", ctx.settings.moduleName)
                    }
                    writer.openBlock(".testTarget(", ")") {
                        writer.write("name: \$S,", ctx.settings.testModuleName)
                        writer.openBlock("dependencies: [", "],") {
                            writer.write("\$S,", ctx.settings.moduleName)
                            writer.write(".product(name: \"SmithyTestUtil\", package: \"smithy-swift\")")
                        }
                        writer.write("path: \"./${ctx.settings.testModuleName}\"")
                    }
                }
            }
        }
    }
}
