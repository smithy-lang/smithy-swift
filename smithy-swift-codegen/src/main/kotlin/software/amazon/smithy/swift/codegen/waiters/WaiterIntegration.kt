package software.amazon.smithy.swift.codegen.waiters

import software.amazon.smithy.model.Model
import software.amazon.smithy.swift.codegen.SwiftDelegator
import software.amazon.smithy.swift.codegen.SwiftSettings
import software.amazon.smithy.swift.codegen.core.CodegenContext
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.SwiftIntegration
import software.amazon.smithy.swift.codegen.model.hasTrait
import software.amazon.smithy.waiters.WaitableTrait

class WaiterIntegration : SwiftIntegration {
    override fun enabledForService(model: Model, settings: SwiftSettings): Boolean {
        return serviceHasWaiters(model)
    }

    override fun writeAdditionalFiles(
        ctx: CodegenContext,
        protoCtx: ProtocolGenerator.GenerationContext,
        delegator: SwiftDelegator
    ) {
        WaiterGenerator(ctx, protoCtx, delegator).render()
    }

    private fun serviceHasWaiters(model: Model): Boolean {
        return model.operationShapes.any { it.hasTrait<WaitableTrait>() }
    }
}
