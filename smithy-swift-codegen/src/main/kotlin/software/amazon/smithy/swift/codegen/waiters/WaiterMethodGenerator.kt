/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.waiters

import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.ServiceShape
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.core.SwiftCodegenContext
import software.amazon.smithy.swift.codegen.model.toLowerCamelCase
import software.amazon.smithy.swift.codegen.utils.toLowerCamelCase
import software.amazon.smithy.swift.codegen.utils.toUpperCamelCase

class WaiterMethodGenerator(
    val writer: SwiftWriter,
    val ctx: SwiftCodegenContext,
    val service: ServiceShape,
    val waitedOperation: OperationShape,
    val waiterName: String
) {
    fun render() {
        val inputTypeName = waitedOperation.inputShape.name
        val outputTypeName = waitedOperation.outputShape.name
        val waitedOperationName = waitedOperation.toLowerCamelCase()
        val waiterFunctionName = "waitUntil${waiterName.toUpperCamelCase()}"
        val configMethodName = "${waiterName.toLowerCamelCase()}WaiterConfig"
        val docBody = """
            Initiates waiting for the $waiterName event on the $waitedOperationName operation.
            The operation will be tried and (if necessary) retried until the wait succeeds, fails, or times out.
            Returns a `WaiterOutcome` asynchronously on waiter success, throws an error asynchronously on
            waiter failure or timeout.
            - Parameters:
              - options: `WaiterOptions` to be used to configure this wait.
              - input: The `$inputTypeName` object to be used as a parameter when performing the operation.
            - Returns: A `WaiterOutcome` with the result of the final, successful performance of the operation.
            - Throws: `WaiterFailureError` if the waiter fails due to matching an `Acceptor` with state `failure`
            or there is an error not handled by any `Acceptor.`
            `WaiterTimeoutError` if the waiter times out.
        """.trimIndent()
        writer.writeSingleLineDocs {
            this.write(docBody)
        }
        writer.openBlock(
            "public func \$L(options: WaiterOptions, input: \$L) async throws -> WaiterOutcome<\$L> {",
            "}",
            waiterFunctionName,
            inputTypeName,
            outputTypeName
        ) {
            writer.write(
                "let waiter = Waiter(config: try Self.\$L(), operation: self.\$L(input:))",
                configMethodName,
                waitedOperationName
            )
            writer.write("return try await waiter.waitUntil(options: options, input: input)")
        }
    }
}
