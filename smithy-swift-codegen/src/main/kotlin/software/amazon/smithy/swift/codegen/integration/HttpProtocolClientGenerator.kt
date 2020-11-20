/*
 * Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License").
 * You may not use this file except in compliance with the License.
 * A copy of the License is located at
 *
 *  http://aws.amazon.com/apache2.0
 *
 * or in the "license" file accompanying this file. This file is distributed
 * on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 * express or implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */
package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.codegen.core.CodegenException
import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.knowledge.HttpBinding
import software.amazon.smithy.model.knowledge.HttpBindingIndex
import software.amazon.smithy.model.knowledge.OperationIndex
import software.amazon.smithy.model.knowledge.TopDownIndex
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.ServiceShape
import software.amazon.smithy.model.traits.EnumTrait
import software.amazon.smithy.model.traits.HttpTrait
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.*

/**
 * Renders an implementation of a service interface for HTTP protocol
 */
class HttpProtocolClientGenerator(
    private val model: Model,
    private val symbolProvider: SymbolProvider,
    private val writer: SwiftWriter,
    private val serviceShape: ServiceShape,
    private val features: List<HttpFeature>
) {
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
            writer.write("let config: Configuration")
            writer.write("let serviceName = \"${serviceSymbol.name}\"")
            writer.write("let encoder: RequestEncoder")
            writer.write("let decoder: ResponseDecoder")
            features.forEach { feat ->
                feat.addImportsAndDependencies(writer)
            }
            writer.write("")
            writer.openBlock("init(config: Configuration = Configuration()) throws {", "}") {
                writer.write("client = try SdkHttpClient(engine: config.httpClientEngine, config: config.httpClientConfiguration)")
                features.forEach { feat ->
                    feat.renderInstantiation(writer)
                    if (feat.needsConfigure) {
                        feat.renderConfiguration(writer)
                    }
                }
                writer.write("self.encoder = config.encoder")
                writer.write("self.decoder = config.decoder")
                writer.write("self.config = config")
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
                    renderOperationBody(operationsIndex, it)
                }
                writer.write("")
            }
        }
    }

    private fun renderOperationBody(opIndex: OperationIndex, op: OperationShape) {
        writer.openBlock("do {", "} catch let err { ") {
            renderOperationInputSerializationBlock(opIndex, op)
            renderHttpRequestExecutionBlock(opIndex, op)
        }
        writer.indent()
        writer.write("completion(.failure(.client(.serializationFailed(err.localizedDescription))))")
        writer.dedent()
        writer.write("}")
    }

    // replace labels with any path bindings
    private fun renderUriPath(httpTrait: HttpTrait, pathBindings: List<HttpBinding>, writer: SwiftWriter) {
        val resolvedURIComponents = mutableListOf<String>()
        httpTrait.uri.segments.forEach {
            if (it.isLabel) {
                // spec dictates member name and label name MUST be the same
                val binding = pathBindings.find { binding ->
                    binding.memberName == it.content
                } ?: throw CodegenException("failed to find corresponding member for httpLabel `${it.content}")

                // shape must be string, number, boolean, or timestamp
                val targetShape = model.expectShape(binding.member.target)
                val labelMemberName = binding.member.memberName
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

                // unwrap the label members
                writer.openBlock("guard let $labelMemberName = input.$labelMemberName else {", "}") {
                    writer.write("completion(.failure(.client(ClientError.serializationFailed(\"uri component $labelMemberName unexpectedly nil\"))))")
                    writer.write("return")
                }
                resolvedURIComponents.add("\\($formattedLabel)")
            } else {
                resolvedURIComponents.add(it.content)
            }
        }

        val uri = resolvedURIComponents.joinToString(separator = "/", prefix = "/", postfix = "")
        writer.write("let path = \"$uri\"")
    }

    private fun renderOperationInputSerializationBlock(opIndex: OperationIndex, op: OperationShape) {
        val inputShape = opIndex.getInput(op)
        val httpTrait = op.expectTrait(HttpTrait::class.java)
        val bindingIndex = HttpBindingIndex.of(model)
        val requestBindings = bindingIndex.getRequestBindings(op)
        val pathBindings = requestBindings.values.filter { it.location == HttpBinding.Location.LABEL }
        val httpMethod = httpTrait.method.toLowerCase()

        //TODO: remove this if block after synthetic input/outputs are completely done
        if (inputShape.isEmpty) {
            // no serializer implementation is generated for operations with no input, inline the HTTP
            // protocol request from the operation itself
            // TODO:: Replace host appropriately
            renderUriPath(httpTrait, pathBindings, writer)
            writer.write("let endpoint = Endpoint(host: \"my-api.us-east-2.amazonaws.com\", path: path)")
            writer.write("let headers = Headers()")
            writer.write("let request = SdkHttpRequest(method: .$httpMethod, endpoint: endpoint, headers: headers)")
        } else {
            renderUriPath(httpTrait, pathBindings, writer)
            writer.write("let method = HttpMethodType.$httpMethod")
            writer.write("let request = try input.buildHttpRequest(method: method, path: path, encoder: encoder)")
        }
        //
    }

    private fun renderHttpRequestExecutionBlock(opIndex: OperationIndex, op: OperationShape) {
        val operationErrorName = "${op.defaultName()}Error"
        val outputShapeName = ServiceGenerator.getOperationOutputShapeName(symbolProvider, opIndex, op)
        writer.write("let context = Context(encoder: encoder,")
        writer.indent(5).write("  decoder: decoder,")
        writer.write("  outputType: ${outputShapeName}.self,")
        writer.write("  outputError: ${operationErrorName}.self,")
        writer.write("  operation: ${op.camelCaseName()},")
        writer.write("  serviceName: serviceName)")
        writer.dedent(5)
        writer.write("client.execute(request: request, context: context, completion: completion)")
    }
}
