/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.waiters

import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.ServiceShape
import software.amazon.smithy.swift.codegen.SwiftDelegator
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.core.CodegenContext
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.model.expectShape
import software.amazon.smithy.waiters.Matcher.ErrorTypeMember
import software.amazon.smithy.waiters.WaitableTrait

/**
 * Generate waiters for supporting operations.  See
 * https://smithy.io/2.0/additional-specs/waiters.html for details.
 */
class WaiterGenerator(
    val ctx: CodegenContext,
    val protoCtx: ProtocolGenerator.GenerationContext,
    val delegator: SwiftDelegator
) {

    fun render() {
        val service = ctx.model.expectShape<ServiceShape>(ctx.settings.service)

        // Open a new file Waiters.swift to hold the waiter definitions for this service
        val waiterFilename = "${ctx.settings.moduleName}/Waiters.swift"
        delegator.useFileWriter(waiterFilename) { writer ->
            writer.addImport(SwiftDependency.CLIENT_RUNTIME.target)
            val serviceSymbol = ctx.symbolProvider.toSymbol(service)

            // Only add waiters if Swift version is 5.7 or higher due to type inference issues on 5.6 & below
            writer.write("#if swift(>=5.7)")

            // Render an extension on the service protocol, which will contain the waitUntil... methods
            writer.openBlock("extension \$LProtocol {", "}", serviceSymbol.name) {

                // Get the operation shapes for this service
                val operationShapes = service.allOperations
                    .map { ctx.model.expectShape<OperationShape>(it) }

                // On each operation shape, get only the waitable traits from the operation
                operationShapes.forEach { waitedOperation ->
                    val waitableTraits = waitedOperation.allTraits.values.mapNotNull { it as? WaitableTrait }

                    // On each waitable trait, get all its waiters and render a waitUntil for each
                    waitableTraits.forEach { waitableTrait ->
                        waitableTrait.waiters.forEach { (waiterName, waiter) ->
                            writer.write("")
                            WaiterConfigGenerator(writer, ctx, service, waitedOperation, waiterName, waiter).render()
                            writer.write("")
                            WaiterMethodGenerator(writer, ctx, service, waitedOperation, waiterName).render()
                        }
                    }

                    // If any of this operation's waiters uses an error type matcher, render WaiterTypedError
                    // conformance for this operation's error
                    if (operationUsesErrorTypeMatchers(waitedOperation)) {
                        WaiterTypedErrorGenerator(protoCtx, waitedOperation).render()
                    }
                }
            }

            // Close the Swift version gate block
            writer.write("#endif")
        }
    }

    private fun operationUsesErrorTypeMatchers(waitedOperation: OperationShape): Boolean =
        // Get all the acceptors for this operation, then see if any is of ErrorType
        waitedOperation
            .allTraits.values
            .mapNotNull { it as? WaitableTrait }
            .flatMap { it.waiters.values }
            .flatMap { it.acceptors }
            .any { it.matcher is ErrorTypeMember }
}
