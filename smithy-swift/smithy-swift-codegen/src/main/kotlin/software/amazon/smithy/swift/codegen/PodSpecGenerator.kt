/*
 * Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License").
 * You may not use this file except in compliance with the License.
 * A copy of the License is located at
 *
 *  http://aws.amazon.com/apache2.0
 *
 * or in the "license" file accompanying this file. This file is distributed
 * on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 * express or implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */

package software.amazon.smithy.swift.codegen

import software.amazon.smithy.build.FileManifest
import software.amazon.smithy.codegen.core.SymbolDependency
import software.amazon.smithy.utils.CodeWriter

fun writePodspec(settings: SwiftSettings, fileManifest: FileManifest, dependencies: List<SymbolDependency>) {
    val writer = CodeWriter().apply {
        trimBlankLines()
        trimTrailingSpaces()
        setIndentText("    ")
    }

    writer.openBlock("Pod::Spec.new do |spec|", "end") {
        writer.write("spec.name         = '${settings.moduleName}'")
        writer.write("spec.version      = '${settings.moduleVersion}'")
        writer.write("spec.license      = 'Apache License, Version 2.0'")
        writer.write("spec.homepage     = '${settings.homepage}'")
        writer.write("spec.authors      = { '${settings.author}' => '${settings.author.toLowerCase().replace(" ", "")}' }")
        writer.write("spec.summary      = '${settings.moduleDescription}'")
        writer.write("spec.platform     = :ios, '8.0'")
        writer.write("spec.swift_version = '${settings.swiftVersion}'")
        writer.write("spec.source       = { :git => '${settings.gitRepo}',\n" +
                "                     :tag => ${settings.moduleVersion}}")
        writer.write("spec.requires_arc = true")
        for (dependency in dependencies) {
            writer.write("spec.dependency '${dependency.packageName}', '${dependency.version}'")
        }
        writer.write("spec.source_files = '${settings.moduleName}/*.swift'")
    }

    val contents = writer.toString()
    fileManifest.writeFile("${settings.moduleName}.podspec", contents)
}
