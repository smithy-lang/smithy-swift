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
import software.amazon.smithy.model.traits.EnumTrait
import software.amazon.smithy.model.traits.HttpTrait
import software.amazon.smithy.model.traits.IdempotencyTokenTrait
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.IdempotencyTokenMiddlewareGenerator
import software.amazon.smithy.swift.codegen.ServiceGenerator
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.camelCaseName
import software.amazon.smithy.swift.codegen.defaultName
import software.amazon.smithy.swift.codegen.isBoxed
import software.amazon.smithy.swift.codegen.swiftFunctionParameterIndent

/**
 * Renders an implementation of a service interface for HTTP protocol
 */
open class HttpProtocolClientGenerator(
    ctx: ProtocolGenerator.GenerationContext,
    private val writer: SwiftWriter,
    private val properties: List<ClientProperty>,
    private val serviceConfig: ServiceConfig,
    private val httpBindingResolver: HttpBindingResolver
) {
    private val serviceName: String = ctx.settings.sdkId
    private val model: Model = ctx.model
    private val symbolProvider = ctx.symbolProvider
    private val serviceShape = ctx.service

    fun render() {
        val serviceSymbol = symbolProvider.toSymbol(serviceShape)
        writer.addImport(SwiftDependency.CLIENT_RUNTIME.namespace)
        writer.addFoundationImport()
        renderClientInitialization(serviceSymbol)
        writer.write("")
        renderOperationsInExtension(serviceSymbol)
    }

    private fun renderClientInitialization(serviceSymbol: Symbol) {
        writer.openBlock("public class ${serviceSymbol.name} {", "}") {
            writer.write("let client: SdkHttpClient")
            writer.write("let config: ${serviceConfig.typeName}")
            writer.write("let serviceName = \"${serviceName}\"")
            writer.write("let encoder: RequestEncoder")
            writer.write("let decoder: ResponseDecoder")
            properties.forEach { prop ->
                prop.addImportsAndDependencies(writer)
            }
            writer.write("")
            writer.openBlock("public init(config: ${serviceSymbol.name}Configuration) throws {", "}") {
                writer.write("client = try SdkHttpClient(engine: config.httpClientEngine, config: config.httpClientConfiguration)")
                properties.forEach { prop ->
                    prop.renderInstantiation(writer)
                    if (prop.needsConfigure) {
                        prop.renderConfiguration(writer)
                    }
                    prop.renderInitialization(writer, "config")
                }

                writer.write("self.config = config")
            }
            writer.write("")
            // FIXME: possible move generation of the config to a separate file or above the service client
            renderConfig(serviceSymbol)
        }
    }

    private fun renderConfig(serviceSymbol: Symbol) {

        val configFields = serviceConfig.getConfigFields()
        val inheritance = serviceConfig.getTypeInheritance()
        writer.openBlock("public class ${serviceSymbol.name}Configuration: $inheritance {", "}") {
            writer.write("")
            configFields.forEach {
                writer.write("public var ${it.name}: ${it.type}")
            }
            writer.write("")
            renderConfigInit(configFields)
            writer.write("")
            serviceConfig.renderConvenienceInits(serviceSymbol)
            writer.write("")
            serviceConfig.renderStaticDefaultImplementation(serviceSymbol)
        }
    }

    private fun renderConfigInit(configFields: List<ConfigField>) {
        if (configFields.isNotEmpty()) {
            val configFieldsSortedByName = configFields.sortedBy { it.name }
            writer.openBlock("public init (", ")") {
                for ((index, member) in configFieldsSortedByName.withIndex()) {
                    val memberName = member.name
                    val memberSymbol = member.type
                    if (memberName == null) continue
                    val terminator = if (index == configFieldsSortedByName.size - 1) "" else ","
                    writer.write("\$L: \$L$terminator", memberName, memberSymbol)
                }
            }
            writer.openBlock("{", "}") {
                configFieldsSortedByName.forEach {
                    writer.write("self.\$1L = \$1L", it.name)
                }
            }
        }
    }

    private fun renderOperationsInExtension(serviceSymbol: Symbol) {
        val topDownIndex = TopDownIndex.of(model)
        val operations = topDownIndex.getContainedOperations(serviceShape).sortedBy { it.defaultName() }
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
                val labelMemberName = binding.member.memberName.decapitalize()
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
        writer.write("let path = \"\$L\"", uri)
    }

    protected open fun renderContextAttributes(op: OperationShape) {
        val httpTrait = httpBindingResolver.httpTrait(op)
        val httpMethod = httpTrait.method.toLowerCase()
        // FIXME it over indents if i add another indent, come up with better way to properly indent or format for swift
        writer.write("  .withEncoder(value: encoder)")
        writer.write("  .withDecoder(value: decoder)")
        writer.write("  .withMethod(value: .$httpMethod)")
        writer.write("  .withPath(value: path)")
        writer.write("  .withServiceName(value: serviceName)")
        writer.write("  .withOperation(value: \"${op.camelCaseName()}\")")
        writer.write("  .withIdempotencyTokenGenerator(value: config.idempotencyTokenGenerator)")
    }

    protected open fun renderMiddlewares(op: OperationShape, operationStackName: String) {
        writer.write("$operationStackName.addDefaultOperationMiddlewares()")
        val inputShape = model.expectShape(op.input.get())
        val idempotentMember = inputShape.members().firstOrNull() { it.hasTrait(IdempotencyTokenTrait::class.java) }
        val hasIdempotencyTokenTrait = idempotentMember != null
        if (hasIdempotencyTokenTrait) {
            IdempotencyTokenMiddlewareGenerator(
                writer,
                idempotentMember!!.memberName,
                operationStackName
            ).renderIdempotencyMiddleware()
        }
        val opIndex = OperationIndex.of(model)
        val inputShapeName = ServiceGenerator.getOperationInputShapeName(symbolProvider, opIndex, op)
        writer.write("$operationStackName.buildStep.intercept(position: .before, middleware: ${inputShapeName}HeadersMiddleware(${inputShapeName.decapitalize()}: input))")
        writer.write("$operationStackName.buildStep.intercept(position: .before, middleware: ${inputShapeName}QueryItemMiddleware(${inputShapeName.decapitalize()}: input))")
    }

    private fun renderMiddlewareExecutionBlock(opIndex: OperationIndex, op: OperationShape) {
        val httpTrait = httpBindingResolver.httpTrait(op)
        val requestBindings = httpBindingResolver.requestBindings(op)
        val pathBindings = requestBindings.filter { it.location == HttpBinding.Location.LABEL }
        renderUriPath(httpTrait, pathBindings, writer)
        val operationErrorName = "${op.defaultName()}Error"
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
