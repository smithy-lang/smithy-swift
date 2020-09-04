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
package software.amazon.smithy.swift.codegen

import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Assertions
import org.junit.jupiter.api.Test
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.swift.codegen.integration.HttpProtocolClientGenerator

class HttpProtocolClientGeneratorTests : TestsBase() {
    private val commonTestContents: String

    init {
        var model = createModelFromSmithy("service-generator-test-operations.smithy")

        val provider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(model, "Example")
        val service = model.getShape(ShapeId.from("smithy.example#Example")).get().asServiceShape().get()
        val writer = SwiftWriter("test")
        val serviceShapeIdWithNamespace = "smithy.example#Example"
        val settings = SwiftSettings.from(model, buildDefaultSwiftSettingsObjectNode(serviceShapeIdWithNamespace))
        model = AddOperationShapes.execute(model, settings.getService(model), settings.moduleName)
        val generator = HttpProtocolClientGenerator(model, provider, writer, service, mutableListOf())
        generator.render()
        commonTestContents = writer.toString()
    }

    @Test
    fun `it renders client initialization block`() {
        commonTestContents.shouldContainOnlyOnce("public class ExampleClient {\n" +
                "    let client: HttpClient\n" +
                "    init(config: HttpClientConfiguration = HttpClientConfiguration()) {\n" +
                "        client = HttpClient(config: config)\n" +
                "    }\n" +
                "}"
        )
    }

    @Test
    fun `it renders operation implementations in extension`() {
        commonTestContents.shouldContainOnlyOnce("extension ExampleClient: ExampleClientProtocol {")
    }

    @Test
    fun `it renders non-streaming operation`() {
        commonTestContents.shouldContainOnlyOnce(
            "public func getFoo(input: GetFooRequest, completion: (SdkResult<GetFooResponse, OperationError>) -> Void)\n" +
                    "    {\n" +
                    "        let path = \"/foo\"\n" +
                    "        let method = HttpMethodType.get\n" +
                    "        var request = input.buildHttpRequest(method: method, path: path)\n" +
                    "        client.execute(request: request) { httpResult in\n" +
                    "            switch httpResult {\n" +
                    "                case .failure(let httpClientErr):\n" +
                    "                    completion(.failure(SdkError<OperationError>.unknown(httpClientErr)))\n" +
                    "                    return\n" +
                    "\n" +
                    "                case .success(let httpResp):\n" +
                    "                    if httpResp.statusCode == HttpStatusCode.ok {\n" +
                    "                        if case .data(let data) = httpResp.content {\n" +
                    "                            guard let data = data else {\n" +
                    "                                completion(.failure(ClientError.dataNotFound(\"No data was returned to deserialize\")))\n" +
                    "                            }\n" +
                    "                            let responsePayload = ResponsePayload(body: data, decoder: self.decoder)\n" +
                    "                            let result: Result<GetFooResponse, SdkError<OperationError>> = responsePayload.decode()\n" +
                    "                                .mapError { failure in SdkError<OperationError>.client(failure) }\n" +
                    "                            completion(result)\n" +
                    "                        }\n" +
                    "                    }\n" +
                    "                    else {\n" +
                    "                        completion(.failure(.service(.unknown)))\n" +
                    "                    }\n" +
                    "\n" +
                    "            }\n" +
                    "        }\n" +
                    "    }"
        )
    }

    @Test
    fun `it renders non-streaming operation with no input`() {
        commonTestContents.shouldContainOnlyOnce(
            "public func getFooNoInput(input: GetFooNoInputInput, completion: (SdkResult<GetFooResponse, OperationError>) -> Void)\n" +
                    "    {\n" +
                    "        let path = \"/foo-no-input\"\n" +
                    "        let method = HttpMethodType.get\n" +
                    "        var request = input.buildHttpRequest(method: method, path: path)\n" +
                    "        client.execute(request: request) { httpResult in\n" +
                    "            switch httpResult {\n" +
                    "                case .failure(let httpClientErr):\n" +
                    "                    completion(.failure(SdkError<OperationError>.unknown(httpClientErr)))\n" +
                    "                    return\n" +
                    "\n" +
                    "                case .success(let httpResp):\n" +
                    "                    if httpResp.statusCode == HttpStatusCode.ok {\n" +
                    "                        if case .data(let data) = httpResp.content {\n" +
                    "                            guard let data = data else {\n" +
                    "                                completion(.failure(ClientError.dataNotFound(\"No data was returned to deserialize\")))\n" +
                    "                            }\n" +
                    "                            let responsePayload = ResponsePayload(body: data, decoder: self.decoder)\n" +
                    "                            let result: Result<GetFooResponse, SdkError<OperationError>> = responsePayload.decode()\n" +
                    "                                .mapError { failure in SdkError<OperationError>.client(failure) }\n" +
                    "                            completion(result)\n" +
                    "                        }\n" +
                    "                    }\n" +
                    "                    else {\n" +
                    "                        completion(.failure(.service(.unknown)))\n" +
                    "                    }\n" +
                    "\n" +
                    "            }\n" +
                    "        }\n" +
                    "    }"
        )
    }

    @Test
    fun `it renders non-streaming operation with no output`() {
        commonTestContents.shouldContainOnlyOnce(
            "public func getFooNoOutput(input: GetFooRequest, completion: (SdkResult<GetFooNoOutputOutput, OperationError>) -> Void)\n" +
                    "    {\n" +
                    "        let path = \"/foo-no-output\"\n" +
                    "        let method = HttpMethodType.get\n" +
                    "        var request = input.buildHttpRequest(method: method, path: path)\n" +
                    "        client.execute(request: request) { httpResult in\n" +
                    "            switch httpResult {\n" +
                    "                case .failure(let httpClientErr):\n" +
                    "                    completion(.failure(SdkError<OperationError>.unknown(httpClientErr)))\n" +
                    "                    return\n" +
                    "\n" +
                    "                case .success(let httpResp):\n" +
                    "                    if httpResp.statusCode == HttpStatusCode.ok {\n" +
                    "                        if case .data(let data) = httpResp.content {\n" +
                    "                            guard let data = data else {\n" +
                    "                                completion(.failure(ClientError.dataNotFound(\"No data was returned to deserialize\")))\n" +
                    "                            }\n" +
                    "                            let responsePayload = ResponsePayload(body: data, decoder: self.decoder)\n" +
                    "                            let result: Result<GetFooNoOutputOutput, SdkError<OperationError>> = responsePayload.decode()\n" +
                    "                                .mapError { failure in SdkError<OperationError>.client(failure) }\n" +
                    "                            completion(result)\n" +
                    "                        }\n" +
                    "                    }\n" +
                    "                    else {\n" +
                    "                        completion(.failure(.service(.unknown)))\n" +
                    "                    }\n" +
                    "\n" +
                    "            }\n" +
                    "        }\n" +
                    "    }"
        )
    }

    @Test
    fun `it renders operation with streaming input`() {
        // TODO:: handling the streaming input payload
        commonTestContents.shouldContainOnlyOnce(
            "public func getFooStreamingInput(input: GetFooStreamingRequest, completion: (SdkResult<GetFooResponse, OperationError>) -> Void)\n" +
                    "    {\n" +
                    "        let path = \"/foo-streaming-input\"\n" +
                    "        let method = HttpMethodType.post\n" +
                    "        var request = input.buildHttpRequest(method: method, path: path)\n" +
                    "        do {\n" +
                    "            try encoder.encodeHttpRequest(input, currentHttpRequest: &request)\n" +
                    "        } catch let err {\n" +
                    "            completion(.failure(.client(.serializationFailed(err.localizedDescription))))\n" +
                    "        }\n" +
                    "        client.execute(request: request) { httpResult in\n" +
                    "            switch httpResult {\n" +
                    "                case .failure(let httpClientErr):\n" +
                    "                    completion(.failure(SdkError<OperationError>.unknown(httpClientErr)))\n" +
                    "                    return\n" +
                    "\n" +
                    "                case .success(let httpResp):\n" +
                    "                    if httpResp.statusCode == HttpStatusCode.ok {\n" +
                    "                        if case .data(let data) = httpResp.content {\n" +
                    "                            guard let data = data else {\n" +
                    "                                completion(.failure(ClientError.dataNotFound(\"No data was returned to deserialize\")))\n" +
                    "                            }\n" +
                    "                            let responsePayload = ResponsePayload(body: data, decoder: self.decoder)\n" +
                    "                            let result: Result<GetFooResponse, SdkError<OperationError>> = responsePayload.decode()\n" +
                    "                                .mapError { failure in SdkError<OperationError>.client(failure) }\n" +
                    "                            completion(result)\n" +
                    "                        }\n" +
                    "                    }\n" +
                    "                    else {\n" +
                    "                        completion(.failure(.service(.unknown)))\n" +
                    "                    }\n" +
                    "\n" +
                    "            }\n" +
                    "        }\n" +
                    "    }"
        )
    }

    @Test
    fun `it renders operation with streaming output`() {
        // TODO:: how do we deserialize the streaming output to desired response object using streamingHandler?
        commonTestContents.shouldContainOnlyOnce(
            "public func getFooStreamingOutput(input: GetFooRequest, streamingHandler: StreamingProvider, completion: (SdkResult<GetFooStreamingResponse, OperationError>) -> Void)\n" +
                    "    {\n" +
                    "        let path = \"/foo-streaming-output\"\n" +
                    "        let method = HttpMethodType.post\n" +
                    "        var request = input.buildHttpRequest(method: method, path: path)\n" +
                    "        client.execute(request: request) { httpResult in\n" +
                    "            switch httpResult {\n" +
                    "                case .failure(let httpClientErr):\n" +
                    "                    completion(.failure(SdkError<OperationError>.unknown(httpClientErr)))\n" +
                    "                    return\n" +
                    "\n" +
                    "                case .success(let httpResp):\n" +
                    "                    if httpResp.statusCode == HttpStatusCode.ok {\n" +
                    "                        if case .data(let data) = httpResp.content {\n" +
                    "                            guard let data = data else {\n" +
                    "                                completion(.failure(ClientError.dataNotFound(\"No data was returned to deserialize\")))\n" +
                    "                            }\n" +
                    "                            let responsePayload = ResponsePayload(body: data, decoder: self.decoder)\n" +
                    "                            let result: Result<GetFooStreamingResponse, SdkError<OperationError>> = responsePayload.decode()\n" +
                    "                                .mapError { failure in SdkError<OperationError>.client(failure) }\n" +
                    "                            completion(result)\n" +
                    "                        }\n" +
                    "                    }\n" +
                    "                    else {\n" +
                    "                        completion(.failure(.service(.unknown)))\n" +
                    "                    }\n" +
                    "\n" +
                    "            }\n" +
                    "        }\n" +
                    "    }"
        )
    }

    @Test
    fun `it renders operation with no input and streaming output`() {
        // TODO:: how do we deserialize the streaming output to desired response object using streamingHandler?
        commonTestContents.shouldContainOnlyOnce(
            "public func getFooStreamingOutputNoInput(input: GetFooStreamingOutputNoInputInput, streamingHandler: StreamingProvider, completion: (SdkResult<GetFooStreamingResponse, OperationError>) -> Void)\n" +
                    "    {\n" +
                    "        let path = \"/foo-streaming-output-no-input\"\n" +
                    "        let method = HttpMethodType.post\n" +
                    "        var request = input.buildHttpRequest(method: method, path: path)\n" +
                    "        client.execute(request: request) { httpResult in\n" +
                    "            switch httpResult {\n" +
                    "                case .failure(let httpClientErr):\n" +
                    "                    completion(.failure(SdkError<OperationError>.unknown(httpClientErr)))\n" +
                    "                    return\n" +
                    "\n" +
                    "                case .success(let httpResp):\n" +
                    "                    if httpResp.statusCode == HttpStatusCode.ok {\n" +
                    "                        if case .data(let data) = httpResp.content {\n" +
                    "                            guard let data = data else {\n" +
                    "                                completion(.failure(ClientError.dataNotFound(\"No data was returned to deserialize\")))\n" +
                    "                            }\n" +
                    "                            let responsePayload = ResponsePayload(body: data, decoder: self.decoder)\n" +
                    "                            let result: Result<GetFooStreamingResponse, SdkError<OperationError>> = responsePayload.decode()\n" +
                    "                                .mapError { failure in SdkError<OperationError>.client(failure) }\n" +
                    "                            completion(result)\n" +
                    "                        }\n" +
                    "                    }\n" +
                    "                    else {\n" +
                    "                        completion(.failure(.service(.unknown)))\n" +
                    "                    }\n" +
                    "\n" +
                    "            }\n" +
                    "        }\n" +
                    "    }\n" +
                    "\n" +
                    "}"
        )
    }

    @Test
    fun `it syntactic sanity checks`() {
        // sanity check since we are testing fragments
        var openBraces = 0
        var closedBraces = 0
        var openParens = 0
        var closedParens = 0
        commonTestContents.forEach {
            when (it) {
                '{' -> openBraces++
                '}' -> closedBraces++
                '(' -> openParens++
                ')' -> closedParens++
            }
        }
        Assertions.assertEquals(openBraces, closedBraces)
        Assertions.assertEquals(openParens, closedParens)
    }
}
