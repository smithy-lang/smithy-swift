/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration.middlewares.handlers

import software.amazon.smithy.aws.traits.protocols.RestXmlTrait
import software.amazon.smithy.codegen.core.CodegenException
import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.knowledge.HttpBinding
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.ShapeType
import software.amazon.smithy.model.traits.EnumTrait
import software.amazon.smithy.model.traits.StreamingTrait
import software.amazon.smithy.model.traits.XmlNameTrait
import software.amazon.smithy.swift.codegen.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.Middleware
import software.amazon.smithy.swift.codegen.MiddlewareGenerator
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.HttpBindingDescriptor
import software.amazon.smithy.swift.codegen.integration.HttpBindingResolver
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.steps.OperationSerializeStep
import software.amazon.smithy.swift.codegen.model.getTrait
import software.amazon.smithy.swift.codegen.model.hasTrait
import software.amazon.smithy.swift.codegen.model.targetOrSelf

class HttpBodyMiddleware(
    private val writer: SwiftWriter,
    private val ctx: ProtocolGenerator.GenerationContext,
    inputSymbol: Symbol,
    outputSymbol: Symbol,
    private val outputErrorSymbol: Symbol,
    private val requestBindings: List<HttpBindingDescriptor>
) : Middleware(writer, inputSymbol, OperationSerializeStep(inputSymbol, outputSymbol, outputErrorSymbol)) {

    override val typeName = "${inputSymbol.name}BodyMiddleware"
    companion object {
        fun renderBodyMiddleware(
            ctx: ProtocolGenerator.GenerationContext,
            op: OperationShape,
            httpBindingResolver: HttpBindingResolver
        ) {
            if (MiddlewareShapeUtils.hasHttpBody(ctx.model, op) && MiddlewareShapeUtils.bodyIsHttpPayload(ctx.model, op)) {
                val inputSymbol = MiddlewareShapeUtils.inputSymbol(ctx.symbolProvider, ctx.model, op)
                val outputSymbol = MiddlewareShapeUtils.outputSymbol(ctx.symbolProvider, ctx.model, op)
                val outputErrorSymbol = MiddlewareShapeUtils.outputErrorSymbol(op)
                val rootNamespace = MiddlewareShapeUtils.rootNamespace(ctx.settings)
                val requestBindings = httpBindingResolver.requestBindings(op)
                val headerMiddlewareSymbol = Symbol.builder()
                    .definitionFile("./$rootNamespace/models/${inputSymbol.name}+BodyMiddleware.swift")
                    .name(inputSymbol.name)
                    .build()
                ctx.delegator.useShapeWriter(headerMiddlewareSymbol) { writer ->
                    writer.addImport(SwiftDependency.CLIENT_RUNTIME.target)

                    val bodyMiddleware = HttpBodyMiddleware(writer, ctx, inputSymbol, outputSymbol, outputErrorSymbol, requestBindings)
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
        val bodyMembers = requestBindings.filter {
            it.location == HttpBinding.Location.DOCUMENT || it.location == HttpBinding.Location.LABEL
        }
        if (httpPayload != null) {
            renderExplicitPayload(httpPayload)
        }
    }

    private fun renderExplicitPayload(binding: HttpBindingDescriptor) {
        val memberName = ctx.symbolProvider.toMemberName(binding.member)
        val target = ctx.model.expectShape(binding.member.target)
        val dataDeclaration = "${memberName}Data"
        val bodyDeclaration = "${memberName}Body"

        when (target.type) {
            ShapeType.BLOB -> {
                val isBinaryStream =
                    ctx.model.getShape(binding.member.target).get().hasTrait<StreamingTrait>()
                writer.openBlock("if let $memberName = input.operationInput.$memberName {", "}") {
                    if (!isBinaryStream) {
                        writer.write("let $dataDeclaration = \$L", memberName)
                    }
                    renderEncodedBodyAddedToRequest(memberName, bodyDeclaration, dataDeclaration, isBinaryStream)
                }
            }
            ShapeType.STRING -> {
                val contents = if (target.hasTrait<EnumTrait>()) "$memberName.rawValue" else memberName
                writer.openBlock("if let $memberName = input.operationInput.$memberName {", "}") {
                    writer.write("let $dataDeclaration = \$L.data(using: .utf8)", contents)
                    renderEncodedBodyAddedToRequest(memberName, bodyDeclaration, dataDeclaration)
                }
            }
            ShapeType.ENUM -> {
                val contents = "$memberName.rawValue"
                writer.openBlock("if let $memberName = input.operationInput.$memberName {", "}") {
                    writer.write("let $dataDeclaration = \$L.data(using: .utf8)", contents)
                    renderEncodedBodyAddedToRequest(memberName, bodyDeclaration, dataDeclaration)
                }
            }
            ShapeType.STRUCTURE, ShapeType.UNION -> {
                // delegate to the member encode function
                writer.openBlock("do {", "} catch let err {") {
                    writer.write("let encoder = context.getEncoder()")
                    writer.openBlock("if let $memberName = input.operationInput.$memberName {", "} else {") {

                        val xmlNameTrait = binding.member.getTrait<XmlNameTrait>() ?: target.getTrait<XmlNameTrait>()
                        if (ctx.protocol == RestXmlTrait.ID && xmlNameTrait != null) {
                            val xmlName = xmlNameTrait.value
                            writer.write("let xmlEncoder = encoder as! XMLEncoder")
                            if (target.hasTrait<StreamingTrait>() && target.isUnionShape) {
                                writer.openBlock("guard let messageEncoder = context.getMessageEncoder() else {", "}") {
                                    writer.write("fatalError(\"Message encoder is required for streaming payload\")")
                                }
                                writer.openBlock("guard let messageSigner = context.getMessageSigner() else {", "}") {
                                    writer.write("fatalError(\"Message signer is required for streaming payload\")")
                                }
                                writer.write(
                                    "let encoderStream = \$L(stream: $memberName, messageEncoder: messageEncoder, requestEncoder: encoder, messageSinger: messageSigner)",
                                    ClientRuntimeTypes.EventStream.MessageEncoderStream
                                )
                                writer.write("input.builder.withBody(.stream(encoderStream))")
                            } else {
                                writer.write("let $dataDeclaration = try xmlEncoder.encode(\$L, withRootKey: \"\$L\")", memberName, xmlName)
                                renderEncodedBodyAddedToRequest(memberName, bodyDeclaration, dataDeclaration)
                            }
                        } else {
                            if (target.hasTrait<StreamingTrait>() && target.isUnionShape) {
                                writer.openBlock("guard let messageEncoder = context.getMessageEncoder() else {", "}") {
                                    writer.write("fatalError(\"Message encoder is required for streaming payload\")")
                                }
                                writer.openBlock("guard let messageSigner = context.getMessageSigner() else {", "}") {
                                    writer.write("fatalError(\"Message signer is required for streaming payload\")")
                                }
                                writer.write(
                                    "let encoderStream = \$L(stream: $memberName, messageEncoder: messageEncoder, requestEncoder: encoder, messageSinger: messageSigner)",
                                    ClientRuntimeTypes.EventStream.MessageEncoderStream
                                )
                                writer.write("input.builder.withBody(.stream(encoderStream))")
                            } else {
                                writer.write("let $dataDeclaration = try encoder.encode(\$L)", memberName)
                                renderEncodedBodyAddedToRequest(memberName, bodyDeclaration, dataDeclaration)
                            }
                        }
                    }
                    writer.indent()
                    writer.openBlock("if encoder is JSONEncoder {", "}") {
                        writer.write("// Encode an empty body as an empty structure in JSON")
                        writer.write("let \$L = \"{}\".data(using: .utf8)!", dataDeclaration)
                        renderEncodedBodyAddedToRequest(memberName, bodyDeclaration, dataDeclaration)
                    }
                    writer.dedent()
                    writer.write("}")
                }
                renderErrorCase()
            }
            ShapeType.DOCUMENT -> {
                writer.openBlock("do {", "} catch let err {") {
                    writer.openBlock("if let $memberName = input.operationInput.$memberName {", "}") {
                        writer.write("let encoder = context.getEncoder()")
                        writer.write("let $dataDeclaration = try encoder.encode(\$L)", memberName)
                        renderEncodedBodyAddedToRequest(memberName, bodyDeclaration, dataDeclaration)
                    }
                }
                renderErrorCase()
            }
            else -> throw CodegenException("member shape ${binding.member} serializer not implemented yet")
        }
    }

    private fun renderEncodedBodyAddedToRequest(
        memberName: String,
        bodyDeclaration: String,
        dataDeclaration: String,
        isBinaryStream: Boolean = false
    ) {
        if (isBinaryStream) {
            writer.write("let $bodyDeclaration = \$N(byteStream: $memberName)", ClientRuntimeTypes.Http.HttpBody)
        } else {
            writer.write("let $bodyDeclaration = \$N.data($dataDeclaration)", ClientRuntimeTypes.Http.HttpBody)
        }
        writer.write("input.builder.withBody($bodyDeclaration)")
    }

    private fun renderErrorCase() {
        writer.indent()
        writer.write("throw \$N(err.localizedDescription)", ClientRuntimeTypes.Core.UnknownClientError)
        writer.dedent()
        writer.write("}")
    }
}
