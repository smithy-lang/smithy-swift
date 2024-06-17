package software.amazon.smithy.swift.codegen.utils

import software.amazon.smithy.swift.codegen.SwiftSettings

class ModelFileUtils {

    companion object {
        fun filename(settings: SwiftSettings, filename: String): String {
            return if (settings.mergeModels) {
                "Sources/${settings.moduleName}/Models.swift"
            } else {
                "Sources/${settings.moduleName}/models/$filename.swift"
            }
        }
    }
}
