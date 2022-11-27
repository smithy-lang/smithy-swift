/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.waiters

import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.ServiceShape
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.core.CodegenContext
import software.amazon.smithy.swift.codegen.model.toLowerCamelCase
import software.amazon.smithy.swift.codegen.utils.toLowerCamelCase
import software.amazon.smithy.swift.codegen.utils.toUpperCamelCase
import software.amazon.smithy.waiters.Waiter

class WaiterMethodGenerator(
    val writer: SwiftWriter,
    val ctx: CodegenContext,
    val service: ServiceShape,
    val waitedOperation: OperationShape,
    val waiterName: String,
    val waiter: Waiter
) {
    fun render() {
        val serviceSymbol = ctx.symbolProvider.toSymbol(service)
        val inputType = waitedOperation.inputShape.name
        val outputType = waitedOperation.outputShape.name
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
            val configMethodName = "${waiterName.toLowerCamelCase()}WaiterConfig"
            writer.write("let waiter = Waiter(config: try \$L(), operation: self.\$L(input:))", configMethodName, waitedOperation.toLowerCamelCase())
            writer.write("return try await waiter.waitUntil(options: options, input: input)")
        }
    }
}
