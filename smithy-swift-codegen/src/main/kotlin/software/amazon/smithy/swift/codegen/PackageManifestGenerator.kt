/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
package software.amazon.smithy.swift.codegen

import software.amazon.smithy.build.FileManifest
import software.amazon.smithy.codegen.core.SymbolDependency
import software.amazon.smithy.utils.CodeWriter

fun writePackageManifest(settings: SwiftSettings, fileManifest: FileManifest, dependencies: List<SymbolDependency>, generateTestTarget: Boolean = false) {

    // filter duplicates in dependencies
    val distinctDependencies = dependencies.distinctBy { it.packageName }
    val writer = CodeWriter().apply {
        trimBlankLines()
        trimTrailingSpaces()
        setIndentText("    ")
    }

    writer.write("// swift-tools-version:${settings.swiftVersion}")
    writer.write("")
    writer.write("import PackageDescription")
    writer.write("import class Foundation.ProcessInfo")

    writer.openBlock("let package = Package(", ")") {
        writer.write("name: \"${settings.moduleName}\",")

        writer.openBlock("platforms: [", "],") {
            writer.write(".macOS(.v10_15), .iOS(.v13)")
        }

        writer.openBlock("products: [", "],") {
            writer.write(".library(name: \"${settings.moduleName}\", targets: [\"${settings.moduleName}\"])")
        }

        writer.openBlock("targets: [", "]") {
            writer.openBlock(".target(", "),") {
                writer.write("name: \"${settings.moduleName}\",")
                writer.openBlock("dependencies: [", "],") {
                    for (dependency in distinctDependencies) {
                        writer.openBlock(".product(", "),") {
                            val target = dependency.expectProperty("target", String::class.java)
                            writer.write("name: \"${target}\",")
                            writer.write("package: \"${dependency.packageName}\"")
                        }
                    }
                }
                writer.write("path: \"./${settings.moduleName}\"")
            }
            if (generateTestTarget) {
                writer.openBlock(".testTarget(", ")") {
                    writer.write("name: \"${settings.moduleName}Tests\",")
                    writer.openBlock("dependencies: [", "],") {
                        writer.write("\$S,", settings.moduleName)
                        writer.write(".product(name: \"SmithyTestUtil\", package: \"ClientRuntime\")")
                    }
                    writer.write("path: \"./${settings.moduleName}Tests\"")
                }
            }
        }
    }

    writer.openBlock("if ProcessInfo.processInfo.environment[\"SWIFTCI_USE_LOCAL_DEPS\"] == nil {", "} else {") {
        writer.openBlock("package.dependencies += [", "]") {
            for (dependency in distinctDependencies) {
                writePackageWithURL(writer, dependency)
            }
        }
    }
    writer.indent()
    writer.openBlock("package.dependencies += [", "]") {
        for (dependency in distinctDependencies) {
            val localPath = dependency.expectProperty("localPath", String::class.java)
            val target = dependency.expectProperty("target", String::class.java)

            if (localPath.isNotEmpty()) {
                writer.write(".package(name: \"${target}\", path: \"$localPath\"),")
            } else {
                val target = dependency.expectProperty("target", String::class.java)
                writePackageWithURL(writer, dependency)
            }
        }
    }
    writer.dedent()
    writer.write("}")

    val contents = writer.toString()
    fileManifest.writeFile("Package.swift", contents)
}

fun writePackageWithURL(writer: CodeWriter, dependency: SymbolDependency) {
    writer.openBlock(".package(", "),") {
        val dependencyURL = dependency.expectProperty("url", String::class.java)
        val branch = dependency.getProperty("branch", String::class.java)
        val target = dependency.expectProperty("target", String::class.java)
        writer.write("name: \"$target\",")
        writer.write("url: \"$dependencyURL\",")
        if (branch != null && !branch.isEmpty) {
            val branchGet = branch.get()
            print("branch is $branchGet")
            val branchString = "\"$branchGet\""
            print("branchString is $branchString")
            writer.write(".branch($branchString)")
        } else {
            writer.write("from: ${dependency.version}")
        }
    }
}
