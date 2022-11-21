package software.amazon.smithy.swift.codegen.waiters

import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.ServiceShape
import software.amazon.smithy.swift.codegen.SwiftDelegator
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.SwiftSettings
import software.amazon.smithy.swift.codegen.core.CodegenContext
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.SwiftIntegration
import software.amazon.smithy.swift.codegen.model.expectShape
import software.amazon.smithy.swift.codegen.model.hasTrait
import software.amazon.smithy.waiters.WaitableTrait

/**
 * Generate waiters for supporting operations.  See
 * https://smithy.io/2.0/additional-specs/waiters.html for details.
 */
class WaiterGenerator : SwiftIntegration {
    override fun enabledForService(model: Model, settings: SwiftSettings): Boolean {
        return serviceHasWaiters(model)
    }

    override fun writeAdditionalFiles(
        ctx: CodegenContext,
        protoCtx: ProtocolGenerator.GenerationContext,
        delegator: SwiftDelegator
    ) {
        if (!serviceHasWaiters(ctx.model)) return
        val service = ctx.model.expectShape<ServiceShape>(ctx.settings.service)

        // Open a new file Waiters.swift to hold the waiter definitions for this service
        delegator.useFileWriter("${ctx.settings.moduleName}/Waiters.swift") { writer ->
            writer.addImport(SwiftDependency.CLIENT_RUNTIME.target)
            val serviceSymbol = ctx.symbolProvider.toSymbol(service)

            // Render an extension on the service protocol, which will contain the waitUntil... methods
            writer.openBlock("extension \$LProtocol {", "}", serviceSymbol.name) {

                // Get the operation shapes for this service
                val operationShapes = service.allOperations
                    .map { ctx.model.expectShape<OperationShape>(it) }

                // On each operation shape, get only the waitable traits from the operation
                operationShapes.forEach { waitedOperation ->
                    val waitableTraits = waitedOperation.allTraits.mapNotNull { (_, trait) -> trait as? WaitableTrait }

                    // On each waitable trait, get all its waiters and render a waitUntil for each
                    waitableTraits.forEach { waitableTrait ->
                        waitableTrait.waiters.forEach { (waiterName, waiter) ->
                            WaiterConfigGenerator(writer, ctx, service, waitedOperation, waiterName, waiter).render()
                            WaiterMethodGenerator(writer, ctx, service, waitedOperation, waiterName, waiter).render()
                        }
                    }
                }
            }
        }
    }

    private fun serviceHasWaiters(model: Model): Boolean {
        return model.operationShapes.any { it.hasTrait<WaitableTrait>() }
    }
}