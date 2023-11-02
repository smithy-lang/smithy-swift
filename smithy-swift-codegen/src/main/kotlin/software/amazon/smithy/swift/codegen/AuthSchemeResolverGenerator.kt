package software.amazon.smithy.swift.codegen

import software.amazon.smithy.aws.traits.ServiceTrait
import software.amazon.smithy.aws.traits.auth.SigV4Trait
import software.amazon.smithy.aws.traits.auth.UnsignedPayloadTrait
import software.amazon.smithy.model.knowledge.ServiceIndex
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.model.traits.AuthTrait
import software.amazon.smithy.model.traits.OptionalAuthTrait
import software.amazon.smithy.model.traits.Trait
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.ServiceTypes
import software.amazon.smithy.swift.codegen.utils.clientName
import software.amazon.smithy.swift.codegen.utils.toLowerCamelCase

class AuthSchemeResolverGenerator() {
    fun render(ctx: ProtocolGenerator.GenerationContext) {
        val rootNamespace = ctx.settings.moduleName
        val serviceIndex = ServiceIndex(ctx.model)

        ctx.delegator.useFileWriter("./$rootNamespace/${ClientRuntimeTypes.Core.AuthSchemeResolver.name}.swift") {
            renderResolverParams(serviceIndex, ctx, it)
            it.write("")
            renderResolverProtocol(ctx, it)
            it.write("")
            renderDefaultResolver(serviceIndex, ctx, it)
            it.write("")
            it.addImport(SwiftDependency.CLIENT_RUNTIME.target)
            it.addImport("AWSClientRuntime")
        }
    }

    private fun renderResolverParams(
        serviceIndex: ServiceIndex,
        ctx: ProtocolGenerator.GenerationContext,
        writer: SwiftWriter
    ) {
        writer.apply {
            openBlock(
                "public struct ${getSdkId(ctx)}${ClientRuntimeTypes.Core.AuthSchemeResolverParameters.name}: \$L {",
                "}",
                ServiceTypes.AuthSchemeResolverParams
            ) {
                write("public let operation: String")
                // If service supports SigV4 auth scheme, it's a special-case
                // Region has to be in params in addition to operation string from AuthSchemeResolver protocol
                if (serviceIndex.getEffectiveAuthSchemes(ctx.service).contains(SigV4Trait.ID)) {
                    write("// Region is used for SigV4 auth scheme")
                    write("public let region: String?")
                }
            }
        }
    }

    private fun renderResolverProtocol(ctx: ProtocolGenerator.GenerationContext, writer: SwiftWriter) {
        writer.apply {
            openBlock(
                "public protocol ${getSdkId(ctx)}${ClientRuntimeTypes.Core.AuthSchemeResolver.name}: \$L {",
                "}",
                ServiceTypes.AuthSchemeResolver
            ) {
                // This is just a parent protocol that all auth scheme resolvers of a given service must conform to.
                write("// Intentionally empty.")
                write("// This is the parent protocol that all auth scheme resolver implementations of")
                write("// the service ${getSdkId(ctx)} must conform to.")
            }
        }
    }

    private fun renderDefaultResolver(
        serviceIndex: ServiceIndex,
        ctx: ProtocolGenerator.GenerationContext,
        writer: SwiftWriter
    ) {
        val sdkId = getSdkId(ctx)
        val defaultResolverName = "Default$sdkId${ClientRuntimeTypes.Core.AuthSchemeResolver.name}"
        val serviceProtocolName = sdkId + ClientRuntimeTypes.Core.AuthSchemeResolver.name

        writer.apply {
            openBlock(
                "public struct \$L: \$L {",
                "}",
                defaultResolverName,
                serviceProtocolName
            ) {
                renderResolveAuthSchemeMethod(serviceIndex, ctx, writer)
                write("")
                renderConstructParametersMethod(
                    serviceIndex.getEffectiveAuthSchemes(ctx.service).contains(SigV4Trait.ID),
                    sdkId + ClientRuntimeTypes.Core.AuthSchemeResolverParameters.name,
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
        val serviceParamsName = sdkId + ClientRuntimeTypes.Core.AuthSchemeResolverParameters.name

        writer.apply {
            openBlock(
                "public func resolveAuthScheme(params: \$L) throws -> [AuthOption] {",
                "}",
                ServiceTypes.AuthSchemeResolverParams
            ) {
                // Return value of array of auth options
                write("var validAuthOptions = Array<AuthOption>()")

                // Cast params to service specific params object
                openBlock(
                    "guard let serviceParams = params as? \$L else {",
                    "}",
                    serviceParamsName
                ) {
                    write("throw ClientError.authError(\"Service specific auth scheme parameters type must be passed to auth scheme resolver.\")")
                }

                renderSwitchBlock(serviceIndex, ctx, this)
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
                operations.filter { op ->
                    val opShape = ctx.model.getShape(op).get() as OperationShape
                    opShape.hasTrait(AuthTrait::class.java) ||
                        opShape.hasTrait(OptionalAuthTrait::class.java) ||
                        opShape.hasTrait(UnsignedPayloadTrait::class.java)
                }.forEach { op ->
                    val opName = op.name.toLowerCamelCase()
                    val sdkId = getSdkId(ctx)
                    val validSchemesForOp = serviceIndex.getEffectiveAuthSchemes(
                        ctx.service, op, ServiceIndex.AuthSchemeMode.NO_AUTH_AWARE
                    )
                    renderOperationSwitchCase(
                        sdkId,
                        ctx.model.getShape(op).get() as OperationShape,
                        opName,
                        validSchemesForOp,
                        writer
                    )
                }
                // Handle default case, where operations default to auth schemes defined on service shape
                val validSchemesForService = serviceIndex.getEffectiveAuthSchemes(ctx.service, ServiceIndex.AuthSchemeMode.NO_AUTH_AWARE)
                renderDefaultSwitchCase(getSdkId(ctx), validSchemesForService, writer)
            }

            // Return result
            write("return validAuthOptions")
        }
    }

    private fun renderOperationSwitchCase(sdkId: String, opShape: OperationShape, opName: String, schemes: Map<ShapeId, Trait>, writer: SwiftWriter) {
        writer.apply {
            write("case \"$opName\":")
            indent()
            schemes.forEach {
                if (it.key == SigV4Trait.ID) {
                    write("var sigV4Option = AuthOption(schemeID: \"${it.key}\")")
                    write("sigV4Option.signingProperties.set(key: AttributeKeys.signingName, value: ${(it.value as SigV4Trait).name})")
                    openBlock("guard let region = serviceParams.region else {", "}") {
                        val errorMessage = "\"Missing region in auth scheme parameters for SigV4 auth scheme.\""
                        write("throw ClientError.authError($errorMessage)")
                    }
                    write("sigV4Option.signingProperties.set(key: AttributeKeys.signingRegion, value: region)")

                    val unsignedBody = opShape.hasTrait(UnsignedPayloadTrait::class.java)
                    val signedBodyHeader = if ((sdkId == "s3" || sdkId == "glacier") && !unsignedBody) ".contentSha256" else ".none"
                    // Set .unsignedBody to true IFF operation has UnsignedPayloadTrait
                    write("sigV4Option.signingProperties.set(key: AttributeKeys.unsignedBody, value: $unsignedBody)")
                    // Set .signedBodyHeader to .contentSha256 IFF service is S3 / Glacier AND operation does not have UnsignedPayloadTrait.
                    // Set to .none otherwise.
                    write("sigV4Option.signingProperties.set(key: AttributeKeys.signedBodyHeader, value: $signedBodyHeader)")

                    write("validAuthOptions.append(sigV4Option)")
                } else {
                    write("validAuthOptions.append(AuthOption(schemeID: \"${it.key}\"))")
                }
            }
            dedent()
        }
    }

    private fun renderDefaultSwitchCase(sdkId: String, schemes: Map<ShapeId, Trait>, writer: SwiftWriter) {
        writer.apply {
            write("default:")
            indent()
            schemes.forEach {
                if (it.key == SigV4Trait.ID) {
                    write("var sigV4Option = AuthOption(schemeID: \"${it.key}\")")
                    write("sigV4Option.signingProperties.set(key: AttributeKeys.signingName, value: \"${(it.value as SigV4Trait).name}\")")
                    openBlock("guard let region = serviceParams.region else {", "}") {
                        val errorMessage = "\"Missing region in auth scheme parameters for SigV4 auth scheme.\""
                        write("throw ClientError.authError($errorMessage)")
                    }
                    val signedBodyHeader = if (sdkId == "s3" || sdkId == "glacier") ".contentSha256" else ".none"
                    // Set .unsignedBody to false
                    write("sigV4Option.signingProperties.set(key: AttributeKeys.unsignedBody, value: false)")
                    // Set .signedBodyHeader to .contentSha256 IFF service is S3 / Glacier, set to .none otherwise.
                    write("sigV4Option.signingProperties.set(key: AttributeKeys.signedBodyHeader, value: $signedBodyHeader)")

                    write("validAuthOptions.append(sigV4Option)")
                } else {
                    write("validAuthOptions.append(AuthOption(schemeID: \"${it.key}\"))")
                }
            }
            dedent()
        }
    }

    private fun renderConstructParametersMethod(
        hasSigV4: Boolean,
        returnTypeName: String,
        writer: SwiftWriter
    ) {
        writer.apply {
            openBlock(
                "public func constructParameters(context: HttpContext) throws -> \$L {",
                "}",
                ServiceTypes.AuthSchemeResolverParams
            ) {
                openBlock("guard let opName = context.getOperation() else {", "}") {
                    write("throw ClientError.dataNotFound(\"Operation name not configured in middleware context for auth scheme resolver params construction.\")")
                }
                if (hasSigV4) {
                    write("let opRegion = context.getRegion()")
                    write("return $returnTypeName(operation: opName, region: opRegion)")
                } else {
                    write("return $returnTypeName(operation: opName)")
                }
            }
        }
    }

    // Utility function for returning sdkId from generation context
    fun getSdkId(ctx: ProtocolGenerator.GenerationContext): String {
        return if (ctx.service.hasTrait(ServiceTrait::class.java))
            ctx.service.getTrait(ServiceTrait::class.java).get().sdkId.clientName()
        else ctx.settings.sdkId.clientName()
    }
}
