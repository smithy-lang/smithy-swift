package software.amazon.smithy.swift.codegen.utils

import software.amazon.smithy.swift.codegen.SwiftSettings

class ModelFileUtils {

    companion object {
        fun filename(settings: SwiftSettings, filename: String): String {
            return "Models.swift".takeIf { settings.mergeModels } ?: "models/$filename.swift"
        }
    }
}