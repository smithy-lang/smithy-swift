/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.waiters

import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.ServiceShape
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.core.CodegenContext
import software.amazon.smithy.swift.codegen.utils.toLowerCamelCase
import software.amazon.smithy.swift.codegen.utils.toUpperCamelCase
import software.amazon.smithy.waiters.Waiter

class WaiterConfigGenerator(
    val writer: SwiftWriter,
    val ctx: CodegenContext,
    val service: ServiceShape,
    val waitedOperation: OperationShape,
    val waiterName: String,
    val waiter: Waiter
) {
    fun render() {
        val configFunctionName = "${waiterName.toLowerCamelCase()}WaiterConfig"
        val inputTypeName = waitedOperation.inputShape.name.toUpperCamelCase()
        val outputTypeName = waitedOperation.outputShape.name.toUpperCamelCase()
        writer.openBlock("func \$L() throws -> WaiterConfiguration<\$L, \$L> {", "}", configFunctionName, inputTypeName, outputTypeName) {
            writer.openBlock("let acceptors: [WaiterConfiguration<\$L, \$L>.Acceptor] = [", "]", inputTypeName, outputTypeName) {
                waiter.acceptors.forEach { acceptor ->
                    WaiterAcceptorGenerator(writer, ctx, service, waitedOperation, acceptor).render()
                }
            }
            writer.write(
                "return try WaiterConfiguration<\$L, \$L>(acceptors: acceptors, minDelay: \$L.0, maxDelay: \$L.0)",
                inputTypeName,
                outputTypeName,
                waiter.minDelay,
                waiter.maxDelay
            )
        }
    }
}
