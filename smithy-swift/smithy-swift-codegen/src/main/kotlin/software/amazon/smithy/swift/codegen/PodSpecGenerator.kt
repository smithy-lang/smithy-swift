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
        writer.write("spec.swift_version = '4.0'")
        writer.write("spec.source       = { :git => '${settings.gitRepo}',\n" +
                "                     :tag => ${settings.moduleVersion}}")
        writer.write("spec.requires_arc = true")
        for (dependency in dependencies) {
            writer.write("spec.dependency '${dependency.packageName}', '${dependency.version}'")
        }
        writer.write("spec.source_files       = '${settings.moduleName}/*.swift'")
    }

    val contents = writer.toString()
    fileManifest.writeFile("${settings.moduleName}.podspec", contents)
}
