package software.amazon.smithy.swift.codegen

import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.ServiceShape
import software.amazon.smithy.swift.codegen.core.CodegenContext
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.SwiftIntegration
import software.amazon.smithy.swift.codegen.model.expectShape
import software.amazon.smithy.swift.codegen.model.hasTrait
import software.amazon.smithy.swift.codegen.model.toLowerCamelCase
import software.amazon.smithy.swift.codegen.utils.toUpperCamelCase
import software.amazon.smithy.waiters.WaitableTrait
import software.amazon.smithy.waiters.Waiter

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
                            renderWaitUntilMethodForWaiter(writer, ctx, service, waitedOperation, waiterName, waiter)
                        }
                    }
                }
            }
        }
    }

    private fun serviceHasWaiters(model: Model): Boolean {
        return model.operationShapes.any { it.hasTrait<WaitableTrait>() }
    }

    private fun renderWaitUntilMethodForWaiter(
        writer: SwiftWriter,
        ctx: CodegenContext,
        service: ServiceShape,
        waitedOperation: OperationShape,
        waiterName: String,
        waiter: Waiter
    ) {
        val serviceSymbol = ctx.symbolProvider.toSymbol(service)
        val inputType = waitedOperation.inputShape.name
        val outputType = waitedOperation.outputShape.name
        writer.write("")
        writer.writeSingleLineDocs {
            this.write(
                """
                Initiates waiting for the ${"$"}L event on the ${"$"}L operation.
                The operation will be tried and (if necessary) retried until the wait succeeds, fails, or times out.
                Returns a `WaiterOutcome` asynchronously on waiter success, throws an error asynchronously on
                waiter failure or timeout.
                - Parameters:
                  - options: `WaiterOptions` to be used to configure this wait.
                  - input: The `${"$"}L` object to be used as a parameter when performing the operation.
                - Returns: A `WaiterOutcome` with the result of the final, successful performance of the operation.
                - Throws: `WaiterFailureError` if the waiter fails due to matching an `Acceptor` with state `failure`
                or there is an error not handled by any `Acceptor.`
                `WaiterTimeoutError` if the waiter times out.
                """.trimIndent(),
                waiterName,
                waitedOperation.toLowerCamelCase(),
                inputType
            )
        }
        writer.openBlock(
            "public func waitUntil\$L(options: WaiterOptions, input: \$L) async throws -> WaiterOutcome<\$L> {",
            "}",
            waiterName.toUpperCamelCase(),
            inputType,
            outputType
        ) {
            writer.write("let acceptors: [WaiterConfiguration<\$L, \$L>.Acceptor] = []  // acceptors will be filled in a future PR", inputType, outputType)
            writer.write("let config = try WaiterConfiguration(acceptors: acceptors, minDelay: \$L.0, maxDelay: \$L.0)", waiter.minDelay, waiter.maxDelay)
            writer.write("let waiter = Waiter(config: config, operation: self.\$L(input:))", waitedOperation.toLowerCamelCase())
            writer.write("return try await waiter.waitUntil(options: options, input: input)")
        }
    }
}
