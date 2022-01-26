/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration.middlewares.handlers

import software.amazon.smithy.codegen.core.CodegenException
import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.knowledge.HttpBinding
import software.amazon.smithy.model.knowledge.OperationIndex
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.ShapeType
import software.amazon.smithy.model.traits.EnumTrait
import software.amazon.smithy.model.traits.StreamingTrait
import software.amazon.smithy.swift.codegen.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.Middleware
import software.amazon.smithy.swift.codegen.MiddlewareGenerator
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.HttpBindingDescriptor
import software.amazon.smithy.swift.codegen.integration.HttpBindingResolver
import software.amazon.smithy.swift.codegen.integration.HttpProtocolBodyMiddlewareGeneratorFactory
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.steps.OperationSerializeStep
import software.amazon.smithy.swift.codegen.model.hasTrait

class HttpBodyMiddleware(
    private val writer: SwiftWriter,
    private val ctx: ProtocolGenerator.GenerationContext,
    inputSymbol: Symbol,
    outputSymbol: Symbol,
    outputErrorSymbol: Symbol,
    private val requestBindings: List<HttpBindingDescriptor>
) : Middleware(writer, inputSymbol, OperationSerializeStep(inputSymbol, outputSymbol, outputErrorSymbol)) {

    override val typeName = "${inputSymbol.name}BodyMiddleware"
    companion object {
        fun renderBodyMiddleware(
            ctx: ProtocolGenerator.GenerationContext,
            op: OperationShape,
            httpBindingResolver: HttpBindingResolver,
            httpProtocolBodyMiddleware: HttpProtocolBodyMiddlewareGeneratorFactory
        ) {
            val opIndex = OperationIndex.of(ctx.model)
            val inputShape = opIndex.getInput(op).get()

            if (httpProtocolBodyMiddleware.shouldRenderHttpBodyMiddleware(inputShape)) {
                val inputSymbol = MiddlewareShapeUtils.inputSymbol(ctx.symbolProvider, ctx.model, op)
                val outputSymbol = MiddlewareShapeUtils.outputSymbol(ctx.symbolProvider, ctx.model, op)
                val outputErrorSymbol = MiddlewareShapeUtils.outputErrorSymbol(op)
                val rootNamespace = MiddlewareShapeUtils.rootNamespace(ctx.settings)

                val headerMiddlewareSymbol = Symbol.builder()
                    .definitionFile("./$rootNamespace/models/${inputSymbol.name}+BodyMiddleware.swift")
                    .name(inputSymbol.name)
                    .build()
                ctx.delegator.useShapeWriter(headerMiddlewareSymbol) { writer ->
                    writer.addImport(SwiftDependency.CLIENT_RUNTIME.target)
                    val requestBindings = httpBindingResolver.requestBindings(op)
                    val bodyMiddleware = httpProtocolBodyMiddleware.httpBodyMiddleware(writer, ctx, inputSymbol, outputSymbol, outputErrorSymbol, requestBindings)
                    MiddlewareGenerator(writer, bodyMiddleware).generate()
                }
            }
        }
    }
    override fun generateMiddlewareClosure() {
        renderEncodedBody()
    }

    override fun generateInit() {
        writer.write("public init() {}")
    }

    private fun renderEncodedBody() {
        val httpPayload = requestBindings.firstOrNull { it.location == HttpBinding.Location.PAYLOAD }
        if (httpPayload != null) {
            renderExplicitPayload(httpPayload)
        } else {
            renderSerializablePayload()
        }
    }

    private fun renderSerializablePayload() {
        writer.openBlock("do {", "} catch let err {") {
            writer.openBlock("if try !input.operationInput.allPropertiesAreNull() {", "}") {
                writer.write("let encoder = context.getEncoder()")
                writer.write("let data = try encoder.encode(input.operationInput)")
                writer.write("let body = \$N.data(data)", ClientRuntimeTypes.Http.HttpBody)
                writer.write("input.builder.withBody(body)")
            }
        }
        writer.indent()
        writer.write("return .failure(.client(\$N.serializationFailed(err.localizedDescription)))", ClientRuntimeTypes.Core.ClientError)
        writer.dedent()
        writer.write("}")
    }

    private fun renderExplicitPayload(binding: HttpBindingDescriptor) {
        val memberName = ctx.symbolProvider.toMemberName(binding.member)
        val target = ctx.model.expectShape(binding.member.target)
        val dataDeclaration = "${memberName}data"
        val bodyDeclaration = "${memberName}body"
        writer.openBlock("if let $memberName = input.operationInput.$memberName {", "}") {
            when (target.type) {
                ShapeType.BLOB -> {
                    val isBinaryStream =
                        ctx.model.getShape(binding.member.target).get().hasTrait<StreamingTrait>()
                    val bodyType = if (isBinaryStream) ".stream" else ".data"
                    writer.write("let $dataDeclaration = \$L", memberName)
                    writer.write("let $bodyDeclaration = \$N$bodyType($dataDeclaration)", ClientRuntimeTypes.Http.HttpBody)
                    writer.write("input.builder.withBody($bodyDeclaration)")
                }
                ShapeType.STRING -> {
                    val contents = if (target.hasTrait<EnumTrait>()) "$memberName.rawValue" else memberName
                    writer.write("let $dataDeclaration = \$L.data(using: .utf8)", contents)
                    writer.write("let $bodyDeclaration = \$N.data($dataDeclaration)", ClientRuntimeTypes.Http.HttpBody)
                    writer.write("input.builder.withBody($bodyDeclaration)")
                }
                ShapeType.STRUCTURE, ShapeType.UNION -> {
                    // delegate to the member encode function
                    writer.openBlock("do {", "} catch let err {") {
                        writer.write("let encoder = context.getEncoder()")
                        writer.write("let $dataDeclaration = try encoder.encode(\$L)", memberName)
                        writer.write("let $bodyDeclaration = \$N.data($dataDeclaration)", ClientRuntimeTypes.Http.HttpBody)
                        writer.write("input.builder.withBody($bodyDeclaration)")
                    }
                    writer.indent()
                    writer.write("return .failure(.client(ClientError.serializationFailed(err.localizedDescription)))")
                    writer.dedent()
                    writer.write("}")
                }
                ShapeType.DOCUMENT -> {
                    writer.openBlock("do {", "} catch let err {") {
                        writer.write("let encoder = context.getEncoder()")
                        writer.write("let $dataDeclaration = try encoder.encode(\$L)", memberName)
                        writer.write("let $bodyDeclaration = \$N.data($dataDeclaration)", ClientRuntimeTypes.Http.HttpBody)
                        writer.write("input.builder.withBody($bodyDeclaration)")
                    }
                    writer.indent()
                    writer.write("return .failure(.client(\$N.serializationFailed(err.localizedDescription)))", ClientRuntimeTypes.Core.ClientError)
                    writer.dedent()
                    writer.write("}")
                }
                else -> throw CodegenException("member shape ${binding.member} serializer not implemented yet")
            }
        }
    }
}
