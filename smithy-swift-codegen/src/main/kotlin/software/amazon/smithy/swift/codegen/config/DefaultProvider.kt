package software.amazon.smithy.swift.codegen.config

import software.amazon.smithy.swift.codegen.SwiftWriter

data class DefaultProvider(
    val block: (SwiftWriter) -> String,
    val isThrowable: Boolean,
    val isAsync: Boolean
) {
    /**
     * Returns a default value for client configuration
     *
     * For example:
     *
     * // isAsync = true, isThrowable = true, paramNilCheck = null, default = DefaultProvider.region()
     * try await DefaultProvider.region(),
     *
     * // isAsync = false, isThrowable = true, paramNilCheck = retryMode, default = DefaultProvider.region()
     * try retryMode ?? DefaultProvider.region(),
     *
     * // isAsync = false, isThrowable = true, paramNilCheck = retryMode, default = DefaultProvider.logger()
     * DefaultProvider.logger()
     *
     * @param paramNilCheck parameter to nil check
     * @return default value.
     */
    fun render(writer: SwiftWriter, paramNilCheck: String? = null): String {
        var res = block(writer)
        if (paramNilCheck != null)
            res = "$paramNilCheck ?? $res"
        if (isAsync)
            res = "await $res"
        if (isThrowable)
            res = "try $res"
        return res
    }
}
