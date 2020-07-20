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

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.swift.codegen.*
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.knowledge.OperationIndex
import software.amazon.smithy.model.knowledge.TopDownIndex
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.ServiceShape
import software.amazon.smithy.model.traits.HttpTrait
import software.amazon.smithy.utils.StringUtils

/**
 * Renders an implementation of a service interface for HTTP protocol
 */
class HttpProtocolClientGenerator(
    private val model: Model,
    private val symbolProvider: SymbolProvider,
    private val writer: SwiftWriter,
    private val serviceShape: ServiceShape
) {

    private val serializationProtocol = SerializationProtocol.resolve(serviceShape)
    fun render() {
        val serviceSymbol = symbolProvider.toSymbol(serviceShape)
        renderClientInitialization(serviceSymbol)
        writer.write("")
        renderOperationsInExtension(serviceSymbol)
    }

    private fun renderClientInitialization(serviceSymbol: Symbol) {
        writer.openBlock("public class Default${serviceSymbol.name} {", "}") {
            writer.write("let client: HttpClient")
            writer.openBlock("init(config: HttpClientConfiguration = HttpClientConfiguration()) {", "}") {
                writer.write("client = HttpClient(config: config)")
            }
        }
    }

    private fun renderOperationsInExtension(serviceSymbol: Symbol) {
        val topDownIndex = model.getKnowledge(TopDownIndex::class.java)
        val operations = topDownIndex.getContainedOperations(serviceShape).sortedBy { it.defaultName() }
        val operationsIndex = model.getKnowledge(OperationIndex::class.java)

        writer.openBlock("extension Default${serviceSymbol.name}: ${serviceSymbol.name}Protocol {", "}") {
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

    private fun renderOperationInputSerializationBlock(opIndex: OperationIndex, op: OperationShape) {
        val encoderInstance = serializationProtocol.getEncoderInstanceAsString()
        val inputShape = opIndex.getInput(op)
        if (inputShape.isEmpty()) {
            val httpTrait = op.expectTrait(HttpTrait::class.java)
            val uriString = httpTrait.uri.toString()
            val httpMethod = httpTrait.method.toLowerCase()
            // no serializer implementation is generated for operations with no input, inline the HTTP
            // protocol request from the operation itself
            // TODO:: how do we get the host?
            // TODO:: https://awslabs.github.io/smithy/1.0/spec/core/endpoint-traits.html
            writer.write("let endpoint = Endpoint(host: \"my-api.us-east-2.amazonaws.com\", path: \"$uriString\")")
            writer.write("let headers = HttpHeaders()")
            writer.openBlock("guard let request = HttpRequest(method: .$httpMethod, endpoint: endpoint, headers: headers) else {",
                "}") {
                writer.write("return completion(.failure(.client(.serializationFailed(\"Serialization failed\"))))")
            }
        }
        else {
            writer.openBlock("guard let request = input.encodeFor${StringUtils.capitalize(op.id.name)}(encoder: $encoderInstance) else {", "}") {
                writer.write("return completion(.failure(.client(.serializationFailed(\"Serialization failed\"))))")
            }
        }
    }

    private fun renderHttpRequestExecutionBlock(opIndex: OperationIndex, op: OperationShape) {
        writer.openBlock("client.execute(request: request) { httpResult in", "}") {
            renderHttpClientErrorBlock()
            writer.write("let httpResp = try! httpResult.get()")
            renderSuccessfulResponseBlock(opIndex, op)
        }
    }

    private fun renderHttpClientErrorBlock() {
        writer.openBlock("if case .failure(let httpClientErr) = httpResult {", "}") {
            //TODO:: make error more operation specific
            writer.write("completion(.failure(SdkError<OperationError>.unknown(httpClientErr)))")
            writer.write("return")
        }
    }

    private fun renderSuccessfulResponseBlock(opIndex: OperationIndex, op: OperationShape) {
        writer.openBlock("if httpResp.statusCode == HttpStatusCode.ok {", "}") {
            writer.openBlock("if case .data(let data) = httpResp.content {", "}") {
                val decoderInstance = serializationProtocol.getDecoderInstanceAsString()
                writer.write("let responsePayload = ResponsePayload(body: data!, decoder: $decoderInstance)")
                val outputShapeName = ServiceGenerator.getOperationOutputShapeName(symbolProvider, opIndex, op)
                val outputShapeNameOrNil = outputShapeName?.map { it }?.orElse("nil")
                // TODO:: generate more specific operation error
                writer.write("let result: Result<$outputShapeNameOrNil, SdkError<OperationError>> = responsePayload.decode()")
                writer.write("    .mapError { failure in SdkError<OperationError>.client(failure) }")
                writer.write("completion(result)")
            }

            // HTTP request failed to execute
            writer.openBlock("else {", "}") {
                // TODO:: map the HttpError to a service specific error
                writer.write("completion(.failure(.service(.unknown)))")
            }
        }
    }
}
