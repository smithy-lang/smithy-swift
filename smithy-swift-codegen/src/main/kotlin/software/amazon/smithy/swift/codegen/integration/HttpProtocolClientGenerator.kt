/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.knowledge.OperationIndex
import software.amazon.smithy.model.knowledge.TopDownIndex
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.swift.codegen.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.ServiceGenerator
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.SwiftTypes
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.middleware.OperationMiddleware
import software.amazon.smithy.swift.codegen.model.camelCaseName
import software.amazon.smithy.swift.codegen.model.capitalizedName

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
        val rootNamespace = ctx.settings.moduleName
        ctx.delegator.useFileWriter("./$rootNamespace/${serviceSymbol.name}+Async.swift") {
            it.write("#if swift(>=5.5)")
            it.addImport(SwiftDependency.CLIENT_RUNTIME.target)
            renderAsyncOperationsInExtension(serviceSymbol, it)
            it.write("#endif")
        }
    }

    private fun renderOperationsInExtension(serviceSymbol: Symbol) {
        val topDownIndex = TopDownIndex.of(model)
        val operations = topDownIndex.getContainedOperations(serviceShape).sortedBy { it.capitalizedName() }
        val operationsIndex = OperationIndex.of(model)

        writer.openBlock("extension ${serviceSymbol.name}: ${serviceSymbol.name}Protocol {", "}") {
            operations.forEach {
                ServiceGenerator.renderOperationDefinition(model, symbolProvider, writer, operationsIndex, it)
                writer.openBlock("{", "}") {
                    val operationStackName = "operation"
                    val generator = MiddlewareExecutionGenerator(ctx, writer, httpBindingResolver, defaultContentType, httpProtocolCustomizable, operationMiddleware, operationStackName)
                    generator.render(operationsIndex, it) { writer, labelMemberName ->
                        writer.write("completion(.failure(.client(\$N.serializationFailed(\"uri component $labelMemberName unexpectedly nil\"))))", ClientRuntimeTypes.Core.ClientError)
                        writer.write("return")
                    }
                    writer.write("let result = $operationStackName.handleMiddleware(context: context.build(), input: input, next: client.getHandler())")
                    writer.write("completion(result)")
                }
                writer.write("")
            }
        }
    }

    private fun renderAsyncOperationsInExtension(serviceSymbol: Symbol, writer: SwiftWriter) {
        val topDownIndex = TopDownIndex.of(model)
        val operations = topDownIndex.getContainedOperations(serviceShape).sortedBy { it.capitalizedName() }
        val operationsIndex = OperationIndex.of(model)
        writer.write("@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, macCatalyst 15.0, *)")
        writer.openBlock("public extension ${serviceSymbol.name} {", "}") {
            operations.forEach {
                ServiceGenerator.renderAsyncOperationDefinition(model, symbolProvider, writer, operationsIndex, it)
                writer.openBlock("{", "}") {
                    renderContinuation(operationsIndex, it, writer)
                }
                writer.write("")
            }
        }
    }

    private fun renderContinuation(opIndex: OperationIndex, op: OperationShape, writer: SwiftWriter) {
        val operationName = op.camelCaseName()
        val continuationName = "${operationName}Continuation"
        writer.write("typealias $continuationName = CheckedContinuation<${ServiceGenerator.getOperationOutputShapeName(ctx.symbolProvider, opIndex, op)}, \$N>", SwiftTypes.Error)
        writer.openBlock("return try await withCheckedThrowingContinuation { (continuation: $continuationName) in", "}") {
            writer.openBlock("$operationName(input: input) { result in", "}") {
                writer.openBlock("switch result {", "}") {
                    writer.write("case .success(let output):")
                    writer.indent().write("continuation.resume(returning: output)").dedent()
                    writer.write("case .failure(let error):")
                    writer.indent().write("continuation.resume(throwing: error)").dedent()
                }
            }
        }
    }
}
