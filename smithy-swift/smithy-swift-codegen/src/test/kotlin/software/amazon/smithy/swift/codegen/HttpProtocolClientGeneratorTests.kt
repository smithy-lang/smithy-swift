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

class HttpProtocolClientGeneratorTests: TestsBase() {
    private val commonTestContents: String

    init {
        val model = createModelFromSmithy("service-generator-test-operations.smithy")

        val provider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(model, "Example")
        val service = model.getShape(ShapeId.from("com.test#Example")).get().asServiceShape().get()
        val writer = SwiftWriter("test")

        val generator = HttpProtocolClientGenerator(model, provider, writer, service)
        generator.render()
        commonTestContents = writer.toString()
    }


    @Test
    fun `it renders client initialization block`() {
        commonTestContents.shouldContainOnlyOnce("public class DefaultExampleClient {\n" +
                "    let client: HttpClient\n" +
                "    init(config: HttpClientConfiguration = HttpClientConfiguration()) {\n" +
                "        client = HttpClient(config: config)\n" +
                "    }\n" +
                "}")
    }

    @Test
    fun `it renders operation implementations in extension`() {
        commonTestContents.shouldContainOnlyOnce("extension DefaultExampleClient: ExampleClientProtocol {")
    }

    @Test
    fun `it renders non-streaming operation`() {
        commonTestContents.shouldContainOnlyOnce(
          "    func getFoo(input: GetFooRequest, completion: (SdkResult<GetFooResponse, OperationError>) -> Void)\n" +
                 "    {\n" +
                 "        guard let request = input.encodeForGetFoo(encoder: JSONEncoder()) else {\n" +
                 "            return completion(.failure(.client(.serializationFailed(\"Serialization failed\"))))\n" +
                 "        }\n" +
                 "        client.execute(request: request) { httpResult in\n" +
                 "            if case .failure(let httpClientErr) = httpResult {\n" +
                 "                completion(.failure(SdkError<OperationError>.unknown(httpClientErr)))\n" +
                 "                return\n" +
                 "            }\n" +
                 "            let httpResp = try! httpResult.get()\n" +
                 "            if httpResp.statusCode == HttpStatusCode.ok {\n" +
                 "                if case .data(let data) = httpResp.content {\n" +
                 "                    let responsePayload = ResponsePayload(body: data!, decoder: JSONDecoder())\n" +
                 "                    let result: Result<GetFooResponse, SdkError<OperationError>> = responsePayload.decode()\n" +
                 "                        .mapError { failure in SdkError<OperationError>.client(failure) }\n" +
                 "                    completion(result)\n" +
                 "                }\n" +
                 "                else {\n" +
                 "                    completion(.failure(.service(.unknown)))\n" +
                 "                }\n" +
                 "            }\n" +
                 "        }\n" +
                 "    }"
         )
    }

    @Test
    fun `it renders non-streaming operation with no input`() {
        commonTestContents.shouldContainOnlyOnce(
            "    func getFooNoInput(completion: (SdkResult<GetFooResponse, OperationError>) -> Void)\n" +
                    "    {\n" +
                    "        let endpoint = Endpoint(host: \"my-api.us-east-2.amazonaws.com\", path: \"/foo-no-input\")\n" +
                    "        let headers = HttpHeaders()\n" +
                    "        guard let request = HttpRequest(method: .get, endpoint: endpoint, headers: headers) else {\n" +
                    "            return completion(.failure(.client(.serializationFailed(\"Serialization failed\"))))\n" +
                    "        }\n" +
                    "        client.execute(request: request) { httpResult in\n" +
                    "            if case .failure(let httpClientErr) = httpResult {\n" +
                    "                completion(.failure(SdkError<OperationError>.unknown(httpClientErr)))\n" +
                    "                return\n" +
                    "            }\n" +
                    "            let httpResp = try! httpResult.get()\n" +
                    "            if httpResp.statusCode == HttpStatusCode.ok {\n" +
                    "                if case .data(let data) = httpResp.content {\n" +
                    "                    let responsePayload = ResponsePayload(body: data!, decoder: JSONDecoder())\n" +
                    "                    let result: Result<GetFooResponse, SdkError<OperationError>> = responsePayload.decode()\n" +
                    "                        .mapError { failure in SdkError<OperationError>.client(failure) }\n" +
                    "                    completion(result)\n" +
                    "                }\n" +
                    "                else {\n" +
                    "                    completion(.failure(.service(.unknown)))\n" +
                    "                }\n" +
                    "            }\n" +
                    "        }\n" +
                    "    }")
    }

    @Test
    fun `it renders non-streaming operation with no output`() {
        commonTestContents.shouldContainOnlyOnce(
            "    func getFooNoOutput(input: GetFooRequest)\n" +
                    "    {\n" +
                    "        guard let request = input.encodeForGetFooNoOutput(encoder: JSONEncoder()) else {\n" +
                    "            return completion(.failure(.client(.serializationFailed(\"Serialization failed\"))))\n" +
                    "        }\n" +
                    "        client.execute(request: request) { httpResult in\n" +
                    "            if case .failure(let httpClientErr) = httpResult {\n" +
                    "                completion(.failure(SdkError<OperationError>.unknown(httpClientErr)))\n" +
                    "                return\n" +
                    "            }\n" +
                    "            let httpResp = try! httpResult.get()\n" +
                    "            if httpResp.statusCode == HttpStatusCode.ok {\n" +
                    "                if case .data(let data) = httpResp.content {\n" +
                    "                    let responsePayload = ResponsePayload(body: data!, decoder: JSONDecoder())\n" +
                    "                    let result: Result<nil, SdkError<OperationError>> = responsePayload.decode()\n" +
                    "                        .mapError { failure in SdkError<OperationError>.client(failure) }\n" +
                    "                    completion(result)\n" +
                    "                }\n" +
                    "                else {\n" +
                    "                    completion(.failure(.service(.unknown)))\n" +
                    "                }\n" +
                    "            }\n" +
                    "        }\n" +
                    "    }\n")
    }

    @Test
    fun `it renders operation with streaming input`() {
        // The encoding of streaming input to HttpRequest is implemented as an extension just like non-streaming input
        commonTestContents.shouldContainOnlyOnce(
            "    func getFooStreamingInput(input: GetFooStreamingRequest, completion: (SdkResult<GetFooResponse, OperationError>) -> Void)\n" +
                    "    {\n" +
                    "        guard let request = input.encodeForGetFooStreamingInput(encoder: JSONEncoder()) else {\n" +
                    "            return completion(.failure(.client(.serializationFailed(\"Serialization failed\"))))\n" +
                    "        }\n" +
                    "        client.execute(request: request) { httpResult in\n" +
                    "            if case .failure(let httpClientErr) = httpResult {\n" +
                    "                completion(.failure(SdkError<OperationError>.unknown(httpClientErr)))\n" +
                    "                return\n" +
                    "            }\n" +
                    "            let httpResp = try! httpResult.get()\n" +
                    "            if httpResp.statusCode == HttpStatusCode.ok {\n" +
                    "                if case .data(let data) = httpResp.content {\n" +
                    "                    let responsePayload = ResponsePayload(body: data!, decoder: JSONDecoder())\n" +
                    "                    let result: Result<GetFooResponse, SdkError<OperationError>> = responsePayload.decode()\n" +
                    "                        .mapError { failure in SdkError<OperationError>.client(failure) }\n" +
                    "                    completion(result)\n" +
                    "                }\n" +
                    "                else {\n" +
                    "                    completion(.failure(.service(.unknown)))\n" +
                    "                }\n" +
                    "            }\n" +
                    "        }\n" +
                    "    }"
        )
    }

    @Test
    fun `it renders operation with streaming output`() {
        // TODO:: how do we deserialize the streaming output to desired response object using streamingHandler?
        commonTestContents.shouldContainOnlyOnce(
            "    func getFooStreamingOutput(input: GetFooRequest, streamingHandler: StreamingProvider, completion: (SdkResult<GetFooStreamingResponse, OperationError>) -> Void)\n" +
                    "    {\n" +
                    "        guard let request = input.encodeForGetFooStreamingOutput(encoder: JSONEncoder()) else {\n" +
                    "            return completion(.failure(.client(.serializationFailed(\"Serialization failed\"))))\n" +
                    "        }\n" +
                    "        client.execute(request: request) { httpResult in\n" +
                    "            if case .failure(let httpClientErr) = httpResult {\n" +
                    "                completion(.failure(SdkError<OperationError>.unknown(httpClientErr)))\n" +
                    "                return\n" +
                    "            }\n" +
                    "            let httpResp = try! httpResult.get()\n" +
                    "            if httpResp.statusCode == HttpStatusCode.ok {\n" +
                    "                if case .data(let data) = httpResp.content {\n" +
                    "                    let responsePayload = ResponsePayload(body: data!, decoder: JSONDecoder())\n" +
                    "                    let result: Result<GetFooStreamingResponse, SdkError<OperationError>> = responsePayload.decode()\n" +
                    "                        .mapError { failure in SdkError<OperationError>.client(failure) }\n" +
                    "                    completion(result)\n" +
                    "                }\n" +
                    "                else {\n" +
                    "                    completion(.failure(.service(.unknown)))\n" +
                    "                }\n" +
                    "            }\n" +
                    "        }\n" +
                    "    }"
        )
    }

    @Test
    fun `it renders operation with no input and streaming output`() {
        // TODO:: how do we deserialize the streaming output to desired response object using streamingHandler?
        commonTestContents.shouldContainOnlyOnce(
            "    func getFooStreamingOutputNoInput(streamingHandler: StreamingProvider, completion: (SdkResult<GetFooStreamingResponse, OperationError>) -> Void)\n" +
                    "    {\n" +
                    "        let endpoint = Endpoint(host: \"my-api.us-east-2.amazonaws.com\", path: \"/foo-streaming-output-no-input\")\n" +
                    "        let headers = HttpHeaders()\n" +
                    "        guard let request = HttpRequest(method: .post, endpoint: endpoint, headers: headers) else {\n" +
                    "            return completion(.failure(.client(.serializationFailed(\"Serialization failed\"))))\n" +
                    "        }\n" +
                    "        client.execute(request: request) { httpResult in\n" +
                    "            if case .failure(let httpClientErr) = httpResult {\n" +
                    "                completion(.failure(SdkError<OperationError>.unknown(httpClientErr)))\n" +
                    "                return\n" +
                    "            }\n" +
                    "            let httpResp = try! httpResult.get()\n" +
                    "            if httpResp.statusCode == HttpStatusCode.ok {\n" +
                    "                if case .data(let data) = httpResp.content {\n" +
                    "                    let responsePayload = ResponsePayload(body: data!, decoder: JSONDecoder())\n" +
                    "                    let result: Result<GetFooStreamingResponse, SdkError<OperationError>> = responsePayload.decode()\n" +
                    "                        .mapError { failure in SdkError<OperationError>.client(failure) }\n" +
                    "                    completion(result)\n" +
                    "                }\n" +
                    "                else {\n" +
                    "                    completion(.failure(.service(.unknown)))\n" +
                    "                }\n" +
                    "            }\n" +
                    "        }\n" +
                    "    }"
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