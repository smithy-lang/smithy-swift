package software.amazon.smithy.swift.codegen.utils

import software.amazon.smithy.model.knowledge.ServiceIndex
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.model.traits.HttpBearerAuthTrait
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.config.DefaultProvider
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyHTTPAuthTypes

open class AuthUtils(
    private val ctx: ProtocolGenerator.GenerationContext,
) {
    val authSchemesDefaultProvider =
        DefaultProvider(
            { getModeledAuthSchemesSupportedBySDK(ctx, it) },
            isThrowable = false,
            isAsync = false,
        )

    fun isSupportedAuthScheme(authSchemeID: ShapeId): Boolean =
        ServiceIndex(ctx.model).getEffectiveAuthSchemes(ctx.service).contains(authSchemeID)

    fun getModeledAuthSchemesSupportedBySDK(
        ctx: ProtocolGenerator.GenerationContext,
        writer: SwiftWriter,
    ): String {
        val effectiveAuthSchemes = ServiceIndex(ctx.model).getEffectiveAuthSchemes(ctx.service)
        var authSchemeList = mutableListOf<String>()

        if (effectiveAuthSchemes.contains(HttpBearerAuthTrait.ID)) {
            authSchemeList += writer.format("\$N()", SmithyHTTPAuthTypes.BearerTokenAuthScheme)
        }

        return addAdditionalSchemes(writer, authSchemeList).joinToString(prefix = "[", postfix = "]")
    }

    open fun addAdditionalSchemes(
        writer: SwiftWriter,
        authSchemeList: MutableList<String>,
    ): List<String> {
        // Override to add any additional auth schemes supported
        return authSchemeList
    }
}
