package software.amazon.smithy.swift.codegen.utils

import software.amazon.smithy.model.knowledge.ServiceIndex
import software.amazon.smithy.model.traits.HttpBearerAuthTrait
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.config.DefaultProvider
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyHTTPAuthTypes

open class AuthUtils(
    private val ctx: ProtocolGenerator.GenerationContext
) {
    val authSchemesDefaultProvider = DefaultProvider(
        { getModeledAuthSchemesSupportedBySDK(ctx, it) },
        isThrowable = false,
        isAsync = false
    )

    fun getModeledAuthSchemesSupportedBySDK(
        ctx: ProtocolGenerator.GenerationContext,
        writer: SwiftWriter,
    ): String {
        val effectiveAuthSchemes = ServiceIndex(ctx.model).getEffectiveAuthSchemes(ctx.service)
        var authSchemeList = arrayOf<String>()

        if (effectiveAuthSchemes.contains(HttpBearerAuthTrait.ID)) {
            authSchemeList += writer.format("\$N()", SmithyHTTPAuthTypes.BearerTokenAuthScheme)
        }

        addAdditionalSchemes(writer, authSchemeList)

        return "[${authSchemeList.joinToString(", ")}]"
    }

    open fun addAdditionalSchemes(writer: SwiftWriter, authSchemeList: Array<String>) {
        // Override to add any additional auth schemes supported
    }
}
