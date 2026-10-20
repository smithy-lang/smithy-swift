package software.amazon.smithy.swift.codegen.utils

import software.amazon.smithy.swift.codegen.SwiftSettings

class SDKFileUtils(
    val settings: SwiftSettings,
) {
    fun rootDirFilePath(
        filename: String,
        extension: String = "swift",
    ): String = "${settings.moduleName}/$filename.$extension"

    fun sourcesDirFilePath(
        filename: String,
        extension: String = "swift",
    ): String = "${settings.moduleName}/Sources/${settings.moduleName}/$filename.$extension"

    fun testsDirFilePath(
        filename: String,
        extension: String = "swift",
    ): String = "${settings.moduleName}/Tests/${settings.testModuleName}/$filename.$extension"

    fun modelFilePath(
        filename: String,
        extension: String = "swift",
    ): String =
        if (settings.mergeModels) {
            "${settings.moduleName}/Sources/${settings.moduleName}/Models.$extension"
        } else {
            "${settings.moduleName}/Sources/${settings.moduleName}/models/$filename.$extension"
        }
}
