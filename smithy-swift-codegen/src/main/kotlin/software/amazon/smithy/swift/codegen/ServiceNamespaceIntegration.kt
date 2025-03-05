package software.amazon.smithy.swift.codegen

import software.amazon.smithy.model.Model
import software.amazon.smithy.swift.codegen.core.SwiftCodegenContext
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.SwiftIntegration
import software.amazon.smithy.swift.codegen.model.nestedNamespaceType
import software.amazon.smithy.swift.codegen.utils.ModelFileUtils

class ServiceNamespaceIntegration : SwiftIntegration {
    override fun enabledForService(
        model: Model,
        settings: SwiftSettings,
    ): Boolean = true

    override fun writeAdditionalFiles(
        ctx: SwiftCodegenContext,
        protoCtx: ProtocolGenerator.GenerationContext,
        delegator: SwiftDelegator,
    ) {
        val service = ctx.settings.getService(ctx.model)
        val namespaceName = service.nestedNamespaceType(ctx.symbolProvider).name
        val filename = ModelFileUtils.filename(ctx.settings, namespaceName)
        delegator.useFileWriter(filename) { writer ->
            writer.write("public enum \$L {}", namespaceName)
        }
    }
}
