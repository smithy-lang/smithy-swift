/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
package software.amazon.smithy.swift.codegen

import software.amazon.smithy.codegen.core.SymbolDependency
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import kotlin.jvm.optionals.getOrNull

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

                val externalDependencies = dependencies.filter {
                    it.getProperty("url", String::class.java).getOrNull() != null ||
                        it.getProperty("id", String::class.java).getOrNull() != null
                }
                val dependenciesByURL = externalDependencies.distinctBy {
                    it.getProperty("url", String::class.java).getOrNull() ?: it.getProperty("id", String::class.java).getOrNull() ?: ""
                }

                writer.openBlock("dependencies: [", "],") {
                    dependenciesByURL.forEach { dependency ->
                        writer.openBlock(".package(", "),") {
                            val id = dependency.getProperty("id", String::class.java).getOrNull()
                            id?.let {
                                writer.write("id: \$S,", it)
                            }
                            val url = dependency.getProperty("url", String::class.java).getOrNull()
                            url?.let {
                                writer.write("url: \$S,", it)
                            }
                            writer.write("from: \$S", dependency.version)
                        }
                    }
                }

                val dependenciesByTarget = externalDependencies.distinctBy { it.expectProperty("target", String::class.java) + it.packageName }

                writer.openBlock("targets: [", "]") {
                    writer.openBlock(".target(", "),") {
                        writer.write("name: \$S,", ctx.settings.moduleName)
                        writer.openBlock("dependencies: [", "]") {
                            for (dependency in dependenciesByTarget) {
                                writer.openBlock(".product(", "),") {
                                    val target = dependency.expectProperty("target", String::class.java)
                                    writer.write("name: \$S,", target)
                                    val id = dependency.getProperty("id", String::class.java).getOrNull()
                                    val packageName = id ?: dependency.packageName
                                    writer.write("package: \$S", packageName)
                                }
                            }
                        }
                    }
                    writer.openBlock(".testTarget(", ")") {
                        writer.write("name: \$S,", ctx.settings.testModuleName)
                        writer.openBlock("dependencies: [", "]") {
                            writer.write("\$S,", ctx.settings.moduleName)
                            writer.write(".product(name: \"SmithyTestUtil\", package: \"smithy-swift\"),")
                        }
                    }
                }
            }
        }
    }
}
