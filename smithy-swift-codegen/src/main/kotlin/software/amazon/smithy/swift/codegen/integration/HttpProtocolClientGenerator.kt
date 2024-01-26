/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.knowledge.OperationIndex
import software.amazon.smithy.model.knowledge.TopDownIndex
import software.amazon.smithy.swift.codegen.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.ServiceGenerator
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.middleware.MiddlewareExecutionGenerator
import software.amazon.smithy.swift.codegen.middleware.OperationMiddleware
import software.amazon.smithy.swift.codegen.model.toUpperCamelCase

/**
 * Renders an implementation of a service interface for HTTP protocol
 */
open class HttpProtocolClientGenerator(
    private val ctx: ProtocolGenerator.GenerationContext,
    private val writer: SwiftWriter,
    serviceConfig: ServiceConfig,
    private val httpBindingResolver: HttpBindingResolver,
    private val defaultContentType: String,
    private val httpProtocolCustomizable: HttpProtocolCustomizable,
    private val operationMiddleware: OperationMiddleware
) {
    private val model: Model = ctx.model
    private val symbolProvider = ctx.symbolProvider
    private val serviceShape = ctx.service
    private val httpProtocolServiceClient = httpProtocolCustomizable.serviceClient(ctx, writer, serviceConfig)
    fun render() {
        val serviceSymbol = symbolProvider.toSymbol(serviceShape)
        writer.addImport(SwiftDependency.CLIENT_RUNTIME.target)
        writer.addImport(SwiftDependency.SWIFT_LOG.target)
        writer.addFoundationImport()
        httpProtocolCustomizable.renderInternals(ctx)
        httpProtocolServiceClient.render(serviceSymbol)
        writer.write("")
        renderOperationsInExtension(serviceSymbol)
    }

    private fun renderOperationsInExtension(serviceSymbol: Symbol) {
        val topDownIndex = TopDownIndex.of(model)
        val operations = topDownIndex.getContainedOperations(serviceShape).sortedBy { it.toUpperCamelCase() }
        val operationsIndex = OperationIndex.of(model)

        writer.openBlock("extension \$L {", "}", serviceSymbol.name) {
            operations.forEach {
                ServiceGenerator.renderOperationDefinition(model, serviceShape, symbolProvider, writer, operationsIndex, it)
                writer.openBlock(" {", "}") {
                    val operationStackName = "operation"
                    val generator = MiddlewareExecutionGenerator(ctx, writer, httpBindingResolver, httpProtocolCustomizable, operationMiddleware, operationStackName)
                    generator.render(serviceShape, it) { writer, labelMemberName ->
                        writer.write(
                            "throw \$N(\"uri component \$L unexpectedly nil\")",
                            ClientRuntimeTypes.Core.UnknownClientError,
                            labelMemberName,
                        )
                    }
                    writer.write(
                        "let result = try await \$L.handleMiddleware(context: context, input: input, next: client.getHandler())",
                        operationStackName,
                    )
                    writer.write("return result")
                }
                writer.write("")
            }
        }
    }
}
