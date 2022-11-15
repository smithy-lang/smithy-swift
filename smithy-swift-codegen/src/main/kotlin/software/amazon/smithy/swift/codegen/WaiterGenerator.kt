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
import software.amazon.smithy.swift.codegen.model.toUpperCamelCase
import software.amazon.smithy.swift.codegen.utils.toLowerCamelCase
import software.amazon.smithy.swift.codegen.utils.toUpperCamelCase
import software.amazon.smithy.waiters.Matcher.ErrorTypeMember
import software.amazon.smithy.waiters.Matcher.InputOutputMember
import software.amazon.smithy.waiters.Matcher.OutputMember
import software.amazon.smithy.waiters.Matcher.SuccessMember
import software.amazon.smithy.waiters.WaitableTrait
import software.amazon.smithy.waiters.Waiter

/**
 * Generate waiters for supporting operations.  See
 * https://smithy.io/2.0/additional-specs/waiters.html for details.
 */
class WaiterGenerator : SwiftIntegration {
    override fun enabledForService(model: Model, settings: SwiftSettings): Boolean =
        model.operationShapes.any { it.hasTrait<WaitableTrait>() }

    override fun writeAdditionalFiles(
        ctx: CodegenContext,
        protoCtx: ProtocolGenerator.GenerationContext,
        delegator: SwiftDelegator
    ) {
        val service = ctx.model.expectShape<ServiceShape>(ctx.settings.service)
        delegator.useFileWriter("${ctx.settings.moduleName}/Waiters.swift") { writer ->
            writer.addImport(SwiftDependency.CLIENT_RUNTIME.target)
            val serviceSymbol = ctx.symbolProvider.toSymbol(service)
            writer.openBlock("extension \$L {", "}", serviceSymbol.name) {
                val waitedOperations = service.allOperations
                    .map { ctx.model.expectShape<OperationShape>(it) }
                    .filter { operationShape -> operationShape.hasTrait(WaitableTrait.ID) }

                waitedOperations.forEach { waitedOperation ->
                    val waitableTraits = waitedOperation.allTraits.mapNotNull { (_, trait) -> trait as? WaitableTrait }
                    waitableTraits.forEach { waitableTrait ->
                        waitableTrait.waiters.forEach { (waiterName, waiter) ->
                            renderWaiterForOperation(writer, ctx, service, waitedOperation, waiterName, waiter)
                        }
                    }
                }
            }
        }
    }

    private fun renderWaiterForOperation(
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
        val docBody = """
            Initiates waiting for the $waiterName event on the ${waitedOperation.toLowerCamelCase()} operation.
            The operation will be tried and (if necessary) retried until the wait succeeds, fails, or times out.
            Returns a `WaiterOutcome` asynchronously on waiter success, throws an error asynchronously on
            waiter failure or timeout.
            - Parameters:
              - options: `WaiterOptions` to be used to configure this wait.
              - input: The `$inputType` object to be used as a parameter when performing the operation.
            - Returns: A `WaiterOutcome` with the result of the final, successful performance of the operation.
            - Throws: `WaiterFailureError` if the waiter fails due to matching an `Acceptor` with state `failure`
            or there is an error not handled by any `Acceptor.`
            `WaiterTimeoutError` if the waiter times out.
        """.trimIndent()
        writer.writeSingleLineDocs {
            this.write(docBody)
        }
        writer.openBlock(
            "public func waitUntil${waiterName.toUpperCamelCase()}(options: WaiterOptions, input: $inputType) async throws -> WaiterOutcome<$outputType> {",
            "}"
        ) {
            writer.write("let acceptors: [WaiterConfiguration<$inputType, $outputType>.Acceptor] =")
            renderAcceptors(writer, ctx, service, waitedOperation, waiterName, waiter)
            writer.write("let config = try WaiterConfiguration(acceptors: acceptors, minDelay: ${waiter.minDelay}.0, maxDelay: ${waiter.maxDelay}.0)")
            writer.write("let waiter = Waiter(config: config, operation: self.${waitedOperation.toLowerCamelCase()}(input:))")
            writer.write("return try await waiter.waitUntil(options: options, input: input)")
        }
    }

    private fun renderAcceptors(
        writer: SwiftWriter,
        ctx: CodegenContext,
        service: ServiceShape,
        waitedOperation: OperationShape,
        waiterName: String,
        waiter: Waiter
    ) {
        writer.openBlock("[", "]") {
            waiter.acceptors.forEach { acceptor ->
                writer.openBlock(".init(state: .${acceptor.state.toString()}) { (input: ${waitedOperation.inputShape.name}, result: Result<${waitedOperation.outputShape.name}, Error>) -> Bool in", "},") {
                    val matcher = acceptor.matcher
                    when (matcher) {
                        is SuccessMember -> {
                            writer.openBlock("switch result {", "}") {
                                writer.write("case .success: return ${if (matcher.value) "true" else "false"}")
                                writer.write("case .failure: return ${if (matcher.value) "false" else "true"}")
                            }
                        }
                        is OutputMember -> {
                            writer.write("Output matcher here.  PathMatcher: ${matcher.value.toString()}")
                        }
                        is InputOutputMember -> {
                            val inputShape = ctx.model.getShape(waitedOperation.inputShape)
                            val outputShape = ctx.model.getShape(waitedOperation.outputShape)

                            writer.write("I/O matcher here.  PathMatcher: ${matcher.value.toString()}")
                        }
                        is ErrorTypeMember -> {
                            val errorTypeName = "${waitedOperation.toUpperCamelCase()}OutputError"
                            var errorEnumCaseName = "${matcher.value.toLowerCamelCase()}"
                            writer.openBlock("switch result {", "}") {
                                writer.write("case .failure(error as $errorTypeName):")
                                writer.indent()
                                writer.write("if case .$errorEnumCaseName = error { return true } else { return false }")
                                writer.dedent()
                                writer.write("default: return false")
                            }
                        }
                        else -> {
                            writer.write("UNKNOWN")
                        }
                    }
                }
            }
        }
    }
}
