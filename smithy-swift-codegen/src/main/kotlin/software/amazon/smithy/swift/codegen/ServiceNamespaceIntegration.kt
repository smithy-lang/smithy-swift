package software.amazon.smithy.swift.codegen

import software.amazon.smithy.model.Model
import software.amazon.smithy.swift.codegen.core.CodegenContext
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.SwiftIntegration
import software.amazon.smithy.swift.codegen.model.nestedNamespaceType

class ServiceNamespaceIntegration : SwiftIntegration {
    override fun enabledForService(model: Model, settings: SwiftSettings): Boolean {
        return true
    }

    override fun writeAdditionalFiles(
        ctx: CodegenContext,
        protoCtx: ProtocolGenerator.GenerationContext,
        delegator: SwiftDelegator
    ) {
        val service = ctx.settings.getService(ctx.model)
        val namespaceName = service.nestedNamespaceType(ctx.symbolProvider)
        val filename = "${ctx.settings.moduleName}/Models/$namespaceName.swift"
        delegator.useFileWriter(filename) { writer ->
            writer.write("public enum \$L {}", namespaceName)
        }
    }
}
