package software.amazon.smithy.swift.codegen

import software.amazon.smithy.aws.traits.ServiceTrait
import software.amazon.smithy.aws.traits.auth.SigV4Trait
import software.amazon.smithy.aws.traits.auth.UnsignedPayloadTrait
import software.amazon.smithy.codegen.core.CodegenException
import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.knowledge.ServiceIndex
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.model.traits.AuthTrait
import software.amazon.smithy.model.traits.OptionalAuthTrait
import software.amazon.smithy.model.traits.Trait
import software.amazon.smithy.rulesengine.language.EndpointRuleSet
import software.amazon.smithy.rulesengine.language.syntax.parameters.Parameter
import software.amazon.smithy.rulesengine.language.syntax.parameters.ParameterType
import software.amazon.smithy.rulesengine.traits.EndpointRuleSetTrait
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.model.boxed
import software.amazon.smithy.swift.codegen.model.buildSymbol
import software.amazon.smithy.swift.codegen.model.defaultValue
import software.amazon.smithy.swift.codegen.model.getTrait
import software.amazon.smithy.swift.codegen.utils.clientName
import software.amazon.smithy.swift.codegen.utils.toLowerCamelCase
import java.util.Locale

class AuthSchemeResolverGenerator {
    fun render(ctx: ProtocolGenerator.GenerationContext) {
        val rootNamespace = ctx.settings.moduleName
        val serviceIndex = ServiceIndex(ctx.model)

        ctx.delegator.useFileWriter("./$rootNamespace/$AUTH_SCHEME_RESOLVER.swift") {
            renderServiceSpecificAuthResolverParamsStruct(serviceIndex, ctx, it)
            it.write("")
            renderServiceSpecificAuthResolverProtocol(ctx, it)
            it.write("")
            renderServiceSpecificDefaultResolver(serviceIndex, ctx, it)
            it.write("")
            it.addImport(SwiftDependency.CLIENT_RUNTIME.target)
        }
    }

    private fun renderServiceSpecificAuthResolverParamsStruct(
        serviceIndex: ServiceIndex,
        ctx: ProtocolGenerator.GenerationContext,
        writer: SwiftWriter
    ) {
        writer.apply {
            openBlock(
                "public struct ${getSdkId(ctx)}${ClientRuntimeTypes.Auth.AuthSchemeResolverParams.name}: \$L {",
                "}",
                ClientRuntimeTypes.Auth.AuthSchemeResolverParams
            ) {
                write("public let operation: String")

                if (usesRulesBasedAuthResolver(ctx)) {
                    // For rules based auth scheme resolvers, auth scheme resolver parameters must have
                    //   1-to-1 mapping of endpoint parameters, since rules based auth scheme resolvers rely on
                    //   endpoint resolver's auth scheme resolution to resolve an auth scheme.
                    renderEndpointParamFields(ctx, this)
                } else {
                    // If service supports SigV4/SigV4a auth scheme, it's a special-case for now - change once
                    // it becomes possible at model level to notate custom members for a given auth scheme.
                    // Region has to be in params in addition to operation string.
                    if (serviceIndex.getEffectiveAuthSchemes(ctx.service).contains(SigV4Trait.ID)) {
                        write("// Region is used for SigV4 auth scheme")
                        write("public let region: String?")
                    }
                }
            }
        }
    }

    private fun renderEndpointParamFields(ctx: ProtocolGenerator.GenerationContext, writer: SwiftWriter) {
        writer.apply {
            val ruleSetNode = ctx.service.getTrait<EndpointRuleSetTrait>()?.ruleSet
            val ruleSet = if (ruleSetNode != null) EndpointRuleSet.fromNode(ruleSetNode) else null
            ruleSet?.parameters?.toList()?.sortedBy { it.name.toString() }?.let { sortedParameters ->
                sortedParameters.forEach { param ->
                    val memberName = param.name.toString().toLowerCamelCase()
                    val memberSymbol = param.toSymbol()
                    val optional = if (param.isRequired) "" else "?"
                    param.documentation.orElse(null)?.let { write("/// $it") }
                    write("public let \$L: \$L$optional", memberName, memberSymbol)
                }
            }
        }
    }

    private fun renderServiceSpecificAuthResolverProtocol(ctx: ProtocolGenerator.GenerationContext, writer: SwiftWriter) {
        writer.apply {
            openBlock(
                "public protocol ${getServiceSpecificAuthSchemeResolverName(ctx)}: \$L {",
                "}",
                ClientRuntimeTypes.Auth.AuthSchemeResolver
            ) {
                // This is just a parent protocol that all auth scheme resolvers of a given service must conform to.
                write("// Intentionally empty.")
                write("// This is the parent protocol that all auth scheme resolver implementations of")
                write("// the service ${getSdkId(ctx)} must conform to.")
            }
        }
    }

    private fun renderServiceSpecificDefaultResolver(
        serviceIndex: ServiceIndex,
        ctx: ProtocolGenerator.GenerationContext,
        writer: SwiftWriter
    ) {
        val sdkId = getSdkId(ctx)

        // Model-based auth scheme resolver is internal implementation detail for services that use rules based resolvers,
        //   and is used as fallback only if endpoint resolver returns no valid auth scheme(s).
        val usesRulesBasedResolver = usesRulesBasedAuthResolver(ctx)
        val defaultResolverName =
            if (usesRulesBasedResolver) "InternalModeled$sdkId$AUTH_SCHEME_RESOLVER"
            else "Default$sdkId$AUTH_SCHEME_RESOLVER"

        // Model-based auth scheme resolver should be private internal impl detail if service uses rules-based resolver.
        val accessModifier = if (usesRulesBasedResolver) "private" else "public"
        val serviceSpecificAuthResolverProtocol = sdkId + AUTH_SCHEME_RESOLVER

        writer.apply {
            writer.openBlock(
                "\$L struct \$L: \$L {",
                "}",
                accessModifier,
                defaultResolverName,
                serviceSpecificAuthResolverProtocol
            ) {
                renderResolveAuthSchemeMethod(serviceIndex, ctx, writer)
                write("")
                renderConstructParametersMethod(
                    serviceIndex.getEffectiveAuthSchemes(ctx.service).contains(SigV4Trait.ID),
                    ctx,
                    writer
                )
            }
        }
    }

    private fun renderResolveAuthSchemeMethod(
        serviceIndex: ServiceIndex,
        ctx: ProtocolGenerator.GenerationContext,
        writer: SwiftWriter
    ) {
        val sdkId = getSdkId(ctx)
        val serviceParamsName = sdkId + ClientRuntimeTypes.Auth.AuthSchemeResolverParams.name

        writer.apply {
            openBlock(
                "public func resolveAuthScheme(params: \$L) throws -> [AuthOption] {",
                "}",
                ClientRuntimeTypes.Auth.AuthSchemeResolverParams
            ) {
                // Return value of array of auth options
                write("var validAuthOptions = [AuthOption]()")
                // Cast params to service specific params object
                openBlock("guard let serviceParams = params as? \$L else {", "}", serviceParamsName) {
                    write("throw ClientError.authError(\"Service specific auth scheme parameters type must be passed to auth scheme resolver.\")")
                }
                // Render switch block
                renderSwitchBlock(serviceIndex, ctx, writer)
                // Return result
                write("return validAuthOptions")
            }
        }
    }

    private fun renderSwitchBlock(
        serviceIndex: ServiceIndex,
        ctx: ProtocolGenerator.GenerationContext,
        writer: SwiftWriter
    ) {
        writer.apply {
            // Switch block for iterating over operation name cases
            openBlock("switch serviceParams.operation {", "}") {
                // Handle each operation name case
                val operations = ctx.service.operations
                operations.forEach {
                    val opShape = ctx.model.getShape(it).get() as OperationShape
                    if (
                        opShape.hasTrait(AuthTrait::class.java) ||
                        opShape.hasTrait(OptionalAuthTrait::class.java) ||
                        opShape.hasTrait(UnsignedPayloadTrait::class.java)
                    ) {
                        val opName = it.name.toLowerCamelCase()
                        val validSchemesForOp = serviceIndex.getEffectiveAuthSchemes(
                            ctx.service,
                            it,
                            ServiceIndex.AuthSchemeMode.NO_AUTH_AWARE
                        )
                        write("case \"$opName\":")
                        renderSwitchCase(validSchemesForOp, writer)
                    }
                }
                // Handle default case, where operations default to auth schemes defined on service shape
                val validSchemesForService =
                    serviceIndex.getEffectiveAuthSchemes(ctx.service, ServiceIndex.AuthSchemeMode.NO_AUTH_AWARE)
                write("default:")
                renderSwitchCase(validSchemesForService, writer)
            }
        }
    }

    private fun renderSwitchCase(schemes: Map<ShapeId, Trait>, writer: SwiftWriter) {
        writer.apply {
            indent()
            schemes.forEach {
                if (it.key == SigV4Trait.ID) {
                    renderSigV4AuthOption(it, writer)
                } else {
                    write("validAuthOptions.append(AuthOption(schemeID: \"${it.key}\"))")
                }
            }
            dedent()
        }
    }

    private fun renderSigV4AuthOption(scheme: Map.Entry<ShapeId, Trait>, writer: SwiftWriter) {
        writer.apply {
            write("var sigV4Option = AuthOption(schemeID: \"${scheme.key}\")")
            write("sigV4Option.signingProperties.set(key: AttributeKeys.signingName, value: \"${(scheme.value as SigV4Trait).name}\")")
            openBlock("guard let region = serviceParams.region else {", "}") {
                write("throw ClientError.authError(\"Missing region in auth scheme parameters for SigV4 auth scheme.\")")
            }
            write("sigV4Option.signingProperties.set(key: AttributeKeys.signingRegion, value: region)")
            write("validAuthOptions.append(sigV4Option)")
        }
    }

    private fun renderConstructParametersMethod(
        hasSigV4: Boolean,
        ctx: ProtocolGenerator.GenerationContext,
        writer: SwiftWriter
    ) {
        writer.apply {
            openBlock(
                "public func constructParameters(context: HttpContext) throws -> \$L {",
                "}",
                ClientRuntimeTypes.Auth.AuthSchemeResolverParams
            ) {
                if (usesRulesBasedAuthResolver(ctx)) {
                    write("return try Default${getSdkId(ctx) + AUTH_SCHEME_RESOLVER}().constructParameters(context: context)")
                } else {
                    openBlock("guard let opName = context.getOperation() else {", "}") {
                        write("throw ClientError.dataNotFound(\"Operation name not configured in middleware context for auth scheme resolver params construction.\")")
                    }
                    val paramType = getSdkId(ctx) + ClientRuntimeTypes.Auth.AuthSchemeResolverParams.name
                    if (hasSigV4) {
                        write("let opRegion = context.getRegion()")
                        write("return $paramType(operation: opName, region: opRegion)")
                    } else {
                        write("return $paramType(operation: opName)")
                    }
                }
            }
        }
    }

    companion object {
        private val AUTH_SCHEME_RESOLVER = "AuthSchemeResolver"

        // Utility function for checking if a service relies on endpoint resolver for auth scheme resolution
        fun usesRulesBasedAuthResolver(ctx: ProtocolGenerator.GenerationContext): Boolean {
            return listOf("s3", "eventbridge", "cloudfront keyvaluestore").contains(ctx.settings.sdkId.lowercase(Locale.US))
        }

        // Utility function for returning sdkId from generation context
        fun getSdkId(ctx: ProtocolGenerator.GenerationContext): String {
            return if (ctx.service.hasTrait(ServiceTrait::class.java))
                ctx.service.getTrait(ServiceTrait::class.java).get().sdkId.clientName()
            else ctx.settings.sdkId.clientName()
        }

        fun getServiceSpecificAuthSchemeResolverName(ctx: ProtocolGenerator.GenerationContext): Symbol {
            return buildSymbol {
                name = "${getSdkId(ctx)}$AUTH_SCHEME_RESOLVER"
            }
        }
    }
}

fun Parameter.toSymbol(): Symbol {
    val swiftType = when (type) {
        ParameterType.STRING -> SwiftTypes.String
        ParameterType.BOOLEAN -> SwiftTypes.Bool
        ParameterType.STRING_ARRAY -> SwiftTypes.StringArray
    }
    var builder = Symbol.builder().name(swiftType.fullName)
    if (!isRequired) {
        builder = builder.boxed()
    }

    default.ifPresent { defaultValue ->
        builder.defaultValue(defaultValue.toString())
    }

    return builder.build()
}
