/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.waiters

import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.ServiceShape
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.core.SwiftCodegenContext
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyWaitersAPITypes
import software.amazon.smithy.swift.codegen.utils.toLowerCamelCase
import software.amazon.smithy.swift.codegen.utils.toUpperCamelCase
import software.amazon.smithy.waiters.Matcher.ErrorTypeMember
import software.amazon.smithy.waiters.Waiter

class WaiterConfigGenerator(
    val writer: SwiftWriter,
    val ctx: SwiftCodegenContext,
    val service: ServiceShape,
    val waitedOperation: OperationShape,
    val waiterName: String,
    val waiter: Waiter
) {
    fun render() {
        val configFunctionName = "${waiterName.toLowerCamelCase()}WaiterConfig"
        val inputTypeName = waitedOperation.inputShape.name.toUpperCamelCase()
        val outputTypeName = waitedOperation.outputShape.name.toUpperCamelCase()
        writer.openBlock(
            "static func \$L() throws -> \$N<\$L, \$L> {",
            "}",
            configFunctionName,
            SmithyWaitersAPITypes.WaiterConfiguration,
            inputTypeName,
            outputTypeName,
        ) {
            writer.openBlock(
                "let acceptors: [\$N<\$L, \$L>.Acceptor] = [",
                "]",
                SmithyWaitersAPITypes.WaiterConfiguration,
                inputTypeName,
                outputTypeName,
            ) {
                waiter.acceptors.forEach { acceptor ->
                    WaiterAcceptorGenerator(writer, ctx, service, waitedOperation, acceptor).render()
                }
            }
            writer.write(
                "return try \$N<\$L, \$L>(acceptors: acceptors, minDelay: \$L.0, maxDelay: \$L.0)",
                SmithyWaitersAPITypes.WaiterConfiguration,
                inputTypeName,
                outputTypeName,
                waiter.minDelay,
                waiter.maxDelay
            )
        }
    }

    var usesErrorTypeMatchers: Boolean =
        waiter.acceptors.any { it.matcher is ErrorTypeMember }
}
