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
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator.Companion.getFormattedDateString

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
        writer.addImport(SwiftDependency.CLIENT_RUNTIME.getPackageName())
        writer.addImport(SwiftDependency.FOUNDATION.getPackageName())
        renderClientInitialization(serviceSymbol)
        writer.write("")
        renderOperationsInExtension(serviceSymbol)
    }

    private fun renderClientInitialization(serviceSymbol: Symbol) {
        writer.openBlock("public class ${serviceSymbol.name} {", "}") {
            writer.write("let client: HttpClient")
            features.forEach { feat ->
                feat.addImportsAndDependencies(writer)
                feat.renderInstantiation(writer)
            }
            writer.openBlock("init(config: HttpClientConfiguration = HttpClientConfiguration()) {", "}") {
                writer.write("client = HttpClient(config: config)")
                features.forEach { feat ->
                    if (feat.needsConfigure) {
                        feat.renderConfiguration(writer)
                    }
                }
            }
        }
    }

    private fun renderOperationsInExtension(serviceSymbol: Symbol) {
        val topDownIndex = model.getKnowledge(TopDownIndex::class.java)
        val operations = topDownIndex.getContainedOperations(serviceShape).sortedBy { it.defaultName() }
        val operationsIndex = model.getKnowledge(OperationIndex::class.java)

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
        renderOperationInputSerializationBlock(opIndex, op)
        renderHttpRequestExecutionBlock(opIndex, op)
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
                    formattedLabel = getFormattedDateString(TimestampFormatTrait.Format.DATE_TIME, labelMemberName)
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
        val bindingIndex = model.getKnowledge(HttpBindingIndex::class.java)
        val requestBindings = bindingIndex.getRequestBindings(op)
        val pathBindings = requestBindings.values.filter { it.location == HttpBinding.Location.LABEL }
        val httpMethod = httpTrait.method.toLowerCase()

        if (inputShape.isEmpty()) {
            // no serializer implementation is generated for operations with no input, inline the HTTP
            // protocol request from the operation itself
            // TODO:: Replace host appropriately
            renderUriPath(httpTrait, pathBindings, writer)
            writer.write("let endpoint = Endpoint(host: \"my-api.us-east-2.amazonaws.com\", path: path)")
            writer.write("let headers = HttpHeaders()")
            writer.write("let request = HttpRequest(method: .$httpMethod, endpoint: endpoint, headers: headers)")
        } else {
            renderUriPath(httpTrait, pathBindings, writer)
            writer.write("let method = HttpMethodType.$httpMethod")
            writer.write("var request = input.buildHttpRequest(method: method, path: path)")
            renderEncodingHttpRequestBlock(writer)
        }
    }

    private fun renderEncodingHttpRequestBlock(writer: SwiftWriter) {
        writer.openBlock("do {", "} catch let err { ") {
            writer.write("try encoder.encodeHttpRequest(input, currentHttpRequest: &request)")
        }
        writer.indent()
        writer.write("completion(.failure(.client(err)))")
        writer.dedent()
        writer.write("}")
    }

    private fun renderHttpRequestExecutionBlock(opIndex: OperationIndex, op: OperationShape) {
        writer.openBlock("client.execute(request: request) { httpResult in", "}") {
            writer.openBlock("switch httpResult { ", "}") {
                renderHttpClientErrorBlock()
                renderSuccessfulResponseBlock(opIndex, op)
            }
        }
    }

    private fun renderHttpClientErrorBlock() {
        writer.openBlock("case .failure(let httpClientErr):")
            .call {
                // TODO:: make error more operation specific
                writer.write("completion(.failure(SdkError<OperationError>.unknown(httpClientErr)))")
                writer.write("return")
            }
            .closeBlock("")
    }

    private fun renderSuccessfulResponseBlock(opIndex: OperationIndex, op: OperationShape) {
        writer.openBlock("case .success(let httpResp):")
            .call {
                writer.openBlock("if httpResp.statusCode == HttpStatusCode.ok {", "}") {
                    writer.openBlock("if case .data(let data) = httpResp.content {", "}") {
                        // TODO:: use HttpFeature to fetch this
                        val decoderInstance = "JSONDecoder()"
                        writer.write("let responsePayload = ResponsePayload(body: data, decoder: $decoderInstance)")
                        val outputShapeName = ServiceGenerator.getOperationOutputShapeName(symbolProvider, opIndex, op)
                        // TODO:: verify handling this deserialization case
                        val resultBlock = outputShapeName?.map {
                            "let result: Result<$it, SdkError<OperationError>> = responsePayload.decode()"
                        }?.orElse("let result: Result<nil, SdkError<OperationError>>")
                        // TODO:: generate more specific operation error
                        writer.write(resultBlock)
                        writer.write("    .mapError { failure in SdkError<OperationError>.client(failure) }")
                        writer.write("completion(result)")
                    }
                }
                // HTTP request failed to execute
                writer.openBlock("else {", "}") {
                    // TODO:: map the HttpError to a service specific error
                    writer.write("completion(.failure(.service(.unknown)))")
                }
            }
            .closeBlock("")
    }
}
