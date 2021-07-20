/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.codegen.core.CodegenException
import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.knowledge.HttpBinding
import software.amazon.smithy.model.knowledge.HttpBindingIndex
import software.amazon.smithy.model.knowledge.OperationIndex
import software.amazon.smithy.model.knowledge.TopDownIndex
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.traits.EndpointTrait
import software.amazon.smithy.model.traits.EnumTrait
import software.amazon.smithy.model.traits.HttpTrait
import software.amazon.smithy.model.traits.IdempotencyTokenTrait
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.IdempotencyTokenMiddlewareGenerator
import software.amazon.smithy.swift.codegen.ServiceGenerator
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.camelCaseName
import software.amazon.smithy.swift.codegen.capitalizedName
import software.amazon.smithy.swift.codegen.isBoxed
import software.amazon.smithy.swift.codegen.swiftFunctionParameterIndent
import software.amazon.smithy.swift.codegen.toMemberNames

/**
 * Renders an implementation of a service interface for HTTP protocol
 */
open class HttpProtocolClientGenerator(
    private val ctx: ProtocolGenerator.GenerationContext,
    private val writer: SwiftWriter,
    properties: List<ClientProperty>,
    serviceConfig: ServiceConfig,
    private val httpBindingResolver: HttpBindingResolver,
    private val defaultContentType: String,
    private val httpProtocolCustomizable: HttpProtocolCustomizable
) {
    private val model: Model = ctx.model
    private val symbolProvider = ctx.symbolProvider
    private val serviceShape = ctx.service
    private val httpProtocolServiceClient = HttpProtocolServiceClient(ctx, writer, properties, serviceConfig)
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
                    renderMiddlewareExecutionBlock(operationsIndex, it)
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
        writer.write("typealias $continuationName = CheckedContinuation<${ServiceGenerator.getOperationOutputShapeName(ctx.symbolProvider, opIndex, op)}, Swift.Error>")
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

    // replace labels with any path bindings
    private fun renderUriPath(httpTrait: HttpTrait, pathBindings: List<HttpBindingDescriptor>, writer: SwiftWriter) {
        val resolvedURIComponents = mutableListOf<String>()
        httpTrait.uri.segments.forEach {
            if (it.isLabel) {
                // spec dictates member name and label name MUST be the same
                val binding = pathBindings.find { binding ->
                    binding.memberName == it.content
                } ?: throw CodegenException("failed to find corresponding member for httpLabel `${it.content}")

                // shape must be string, number, boolean, or timestamp
                val targetShape = model.expectShape(binding.member.target)
                val labelMemberName = ctx.symbolProvider.toMemberNames(binding.member).first.decapitalize()
                val formattedLabel: String
                if (targetShape.isTimestampShape) {
                    val bindingIndex = HttpBindingIndex.of(model)
                    val timestampFormat = bindingIndex.determineTimestampFormat(targetShape, HttpBinding.Location.LABEL, TimestampFormatTrait.Format.DATE_TIME)
                    formattedLabel = ProtocolGenerator.getFormattedDateString(timestampFormat, labelMemberName)
                } else if (targetShape.isStringShape) {
                    val enumRawValueSuffix = targetShape.getTrait(EnumTrait::class.java).map { ".rawValue" }.orElse("")
                    formattedLabel = "$labelMemberName$enumRawValueSuffix"
                } else {
                    formattedLabel = labelMemberName
                }
                val isBoxed = symbolProvider.toSymbol(targetShape).isBoxed()

                // unwrap the label members if boxed
                if (isBoxed) {
                    writer.openBlock("guard let $labelMemberName = input.$labelMemberName else {", "}") {
                        writer.write("completion(.failure(.client(ClientError.serializationFailed(\"uri component $labelMemberName unexpectedly nil\"))))")
                        writer.write("return")
                    }
                } else {
                    writer.write("let $labelMemberName = input.$labelMemberName")
                }
                resolvedURIComponents.add("\\($formattedLabel)")
            } else {
                resolvedURIComponents.add(it.content)
            }
        }

        val uri = resolvedURIComponents.joinToString(separator = "/", prefix = "/", postfix = "")
        writer.write("let urlPath = \"\$L\"", uri)
    }

    private fun renderContextAttributes(op: OperationShape) {
        val httpTrait = httpBindingResolver.httpTrait(op)
        val httpMethod = httpTrait.method.toLowerCase()
        // FIXME it over indents if i add another indent, come up with better way to properly indent or format for swift
        writer.write("  .withEncoder(value: encoder)")
        writer.write("  .withDecoder(value: decoder)")
        writer.write("  .withMethod(value: .$httpMethod)")
        writer.write("  .withPath(value: urlPath)")
        writer.write("  .withServiceName(value: serviceName)")
        writer.write("  .withOperation(value: \"${op.camelCaseName()}\")")
        writer.write("  .withIdempotencyTokenGenerator(value: config.idempotencyTokenGenerator)")
        writer.write("  .withLogger(value: config.logger)")

        op.getTrait(EndpointTrait::class.java).ifPresent {
            val inputShape = model.expectShape(op.input.get())
            val hostPrefix = EndpointTraitConstructor(it, inputShape).construct()
            writer.write("  .withHostPrefix(value: \"\$L\")", hostPrefix)
        }
        val serviceShape = ctx.service
        httpProtocolCustomizable.renderContextAttributes(ctx, writer, serviceShape, op)
    }

    private fun renderMiddlewares(op: OperationShape, operationStackName: String) {
        writer.write("$operationStackName.addDefaultOperationMiddlewares()")
        val inputShape = model.expectShape(op.input.get())
        val inputShapeName = symbolProvider.toSymbol(inputShape).name
        val outputShape = model.expectShape(op.output.get())
        val outputShapeName = symbolProvider.toSymbol(outputShape).name
        val outputErrorName = "${op.capitalizedName()}OutputError"
        val idempotentMember = inputShape.members().firstOrNull() { it.hasTrait(IdempotencyTokenTrait::class.java) }
        val hasIdempotencyTokenTrait = idempotentMember != null
        if (hasIdempotencyTokenTrait) {
            IdempotencyTokenMiddlewareGenerator(
                writer,
                idempotentMember!!.memberName.decapitalize(),
                operationStackName,
                outputShapeName,
                outputErrorName
            ).renderIdempotencyMiddleware()
        }
        writer.write("$operationStackName.serializeStep.intercept(position: .before, middleware: ${inputShapeName}HeadersMiddleware())")
        writer.write("$operationStackName.serializeStep.intercept(position: .before, middleware: ${inputShapeName}QueryItemMiddleware())")
        writer.write("$operationStackName.serializeStep.intercept(position: .before, middleware: ContentTypeMiddleware<$inputShapeName, $outputShapeName, $outputErrorName>(contentType: \"${defaultContentType}\"))")
        val hasHttpBody = inputShape.members().filter { it.isInHttpBody() }.count() > 0
        if (hasHttpBody) {
            writer.write("$operationStackName.serializeStep.intercept(position: .before, middleware: ${inputShapeName}BodyMiddleware())")
        }
        httpProtocolCustomizable.renderMiddlewares(ctx, writer, op, operationStackName)
    }

    private fun renderMiddlewareExecutionBlock(opIndex: OperationIndex, op: OperationShape) {
        val httpTrait = httpBindingResolver.httpTrait(op)
        val requestBindings = httpBindingResolver.requestBindings(op)
        val pathBindings = requestBindings.filter { it.location == HttpBinding.Location.LABEL }
        renderUriPath(httpTrait, pathBindings, writer)
        val operationErrorName = "${op.capitalizedName()}OutputError"
        val inputShapeName = ServiceGenerator.getOperationInputShapeName(symbolProvider, opIndex, op)
        val outputShapeName = ServiceGenerator.getOperationOutputShapeName(symbolProvider, opIndex, op)
        writer.write("let context = HttpContextBuilder()")
        writer.swiftFunctionParameterIndent {
            renderContextAttributes(op)
        }
        val operationStackName = "operation"
        writer.write("var $operationStackName = OperationStack<$inputShapeName, $outputShapeName, $operationErrorName>(id: \"${op.camelCaseName()}\")")
        renderMiddlewares(op, operationStackName)
        writer.write("let result = $operationStackName.handleMiddleware(context: context.build(), input: input, next: client.getHandler())")
        writer.write("completion(result)")
    }
}
