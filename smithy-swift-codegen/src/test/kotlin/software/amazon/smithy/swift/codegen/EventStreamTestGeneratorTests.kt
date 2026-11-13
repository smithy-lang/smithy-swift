package software.amazon.smithy.swift.codegen

/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.string.shouldContain
import io.kotest.matchers.string.shouldContainOnlyOnce
import io.kotest.matchers.string.shouldNotContain
import org.junit.jupiter.api.Test
import software.amazon.smithy.swift.codegen.model.AddOperationShapes

class EventStreamTestGeneratorTests {
    private var model = javaClass.classLoader.getResource("event-stream-tests-trait.smithy").asSmithy()

    private fun newTestContext(): TestContext {
        val settings = model.defaultSettings()
        model = AddOperationShapes.execute(model, settings.getService(model), settings.moduleName)
        return model.newTestContext()
    }

    private val ctx = newTestContext()

    init {
        ctx.generator.generateProtocolUnitTests(ctx.generationCtx)
        ctx.generationCtx.delegator.flushWriters()
    }

    private val inputContents = getTestFileContents("example/Tests/example", "InputStreamEventStreamTests.swift", ctx.manifest)
    private val outputContents = getTestFileContents("example/Tests/example", "OutputStreamEventStreamTests.swift", ctx.manifest)

    @Test
    fun `it renders a Swift Testing suite for each operation with event stream tests`() {
        inputContents.shouldSyntacticSanityCheck()
        outputContents.shouldSyntacticSanityCheck()
        inputContents.shouldContainOnlyOnce("import Testing\n")
        inputContents.shouldContainOnlyOnce("@Suite\nstruct InputStreamEventStreamTests {\n")
        outputContents.shouldContainOnlyOnce("@Suite\nstruct OutputStreamEventStreamTests {\n")
        inputContents.shouldNotContain("XCTest")
    }

    @Test
    fun `it skips tests that only apply to servers`() {
        inputContents.shouldNotContain("ServerOnlyInput")
    }

    @Test
    fun `it renders a request test with initial request and event assertions`() {
        val expected = """
    /// Sends an event with a header & payload.
    @Test
    func test_HeadersAndPayloadInput() async throws {
        // Serialize the request & its events
        let config = try await ExampleClient.ExampleClientConfig(
            awsCredentialIdentityResolver: try SmithyTestUtil.dummyIdentityResolver(),
            region: "us-west-2",
            signingRegion: "us-west-2",
            endpointResolver: example.StaticEndpointResolver(endpoint: try SmithyHTTPAPI.Endpoint(urlString: "https://example.com")),
            idempotencyTokenGenerator: SmithyTestUtil.ProtocolTestIdempotencyTokenGenerator(),
            httpClientEngine: SmithyTestUtil.ProtocolTestClient(),
            httpInterceptorProviders: [SmithyTestUtil.EventStreamTestInterceptorProvider()]
        )
        let client = ExampleClient(config: config)

        var input = InputStreamInput(
            initialMember: "foo"
        )
        let inputEvents: [TestEventStream] = [
            TestEventStream.payloadevent(PayloadEvent(
                header: "bar",
                payload: PayloadStructure(
                    structureMember: "baz"
                )
            ))
            ,
        ]
        input.stream = SmithyTestUtil.EventStreamTestUtil.stream(inputEvents)

        let request = try await SmithyTestUtil.EventStreamTestUtil.captureRequest {
            _ = try await client.inputStream(input: input)
        }

        // Verify the initial request
        #expect(request.method == .post)
        #expect(request.path == "/InputStream")
        #expect(request.headers.value(for: "initial-member") == "foo")
        #expect(!request.headers.exists(name: "forbidden-header"))

        // Verify the request events
        let messages = try await SmithyTestUtil.EventStreamTestUtil.messages(in: request)
        try #require(messages.count == 1)
        #expect(messages[0].headers.value(name: ":message-type") == .string("event"))
        #expect(messages[0].headers.value(name: "blobHeader") == .byteArray(Foundation.Data(base64Encoded: "Zm9v")!))
        #expect(messages[0].headers.value(name: "header") == .string("bar"))
        #expect(messages[0].headers.value(name: "longHeader") == .int64(4294967294))
        #expect(messages[0].headers.value(name: "timestampHeader") == .timestamp(Foundation.Date(timeIntervalSince1970: 1730384114.500)))
        #expect(messages[0].headers.value(name: "forbidden") == nil)
        #expect(messages[0].headers.value(name: ":event-type") != nil)
        #expect(try SmithyTestUtil.EventStreamTestUtil.payload(messages[0].payload, matches: Foundation.Data("{\"structureMember\":\"baz\"}".utf8), mediaType: "application/json"))
    }
"""
        inputContents.shouldContainOnlyOnce(expected)
    }

    @Test
    fun `it sends a request error event by finishing the event stream with the error`() {
        val expected = """
        let inputEvents = [TestEventStream]()
        let inputError = ErrorEvent(
            message: "foo"
        )
        input.stream = SmithyTestUtil.EventStreamTestUtil.stream(inputEvents, finishingWith: inputError)
"""
        inputContents.shouldContainOnlyOnce(expected)
        inputContents.shouldNotContain(".disabled(")
    }

    @Test
    fun `it expects any error from the SDK when a failing request test has no errorId`() {
        val expected = """
        let error = try await SmithyTestUtil.EventStreamTestUtil.sdkError {
            let request = try await SmithyTestUtil.EventStreamTestUtil.captureRequest {
                _ = try await client.inputStream(input: input)
            }
            _ = try await request.body.readData()
        }
        #expect(error != nil, "Expected the SDK to throw an error")
    }
"""
        inputContents.shouldContainOnlyOnce(expected)
    }

    @Test
    fun `it expects the errorId type when a failing request test has one`() {
        val expected = """
        await #expect(throws: ErrorEvent.self) {
            let request = try await SmithyTestUtil.EventStreamTestUtil.captureRequest {
                _ = try await client.inputStream(input: input)
            }
            _ = try await request.body.readData()
        }
    }
"""
        inputContents.shouldContainOnlyOnce(expected)
    }

    @Test
    fun `it renders a response test from event bytes, or from headers & body when bytes are absent`() {
        val expectedBody = """
        var body = Foundation.Data()
        body.append(Foundation.Data(base64Encoded: "AAAAAA==")!)
        body.append(try SmithyTestUtil.EventStreamTestUtil.encode([SmithyEventStreamsAPI.Message(headers: [SmithyEventStreamsAPI.Header(name: ":event-type", value: .string("payloadEvent")), SmithyEventStreamsAPI.Header(name: ":message-type", value: .string("event")), SmithyEventStreamsAPI.Header(name: "header", value: .string("qux"))], payload: Foundation.Data())]))
        let httpResponse = SmithyTestUtil.EventStreamTestUtil.httpResponse(
            statusCode: 200,
            headers: [
                "Content-Type": "application/vnd.amazon.eventstream",
            ],
            body: body
        )
"""
        outputContents.shouldContainOnlyOnce(expectedBody)
        val expectedConfig = """
            retryStrategyOptions: SmithyTestUtil.ProtocolTestRetryStrategyOptions.make(),
            httpClientEngine: SmithyTestUtil.ProtocolResponseTestClient(httpResponse: httpResponse),
"""
        outputContents.shouldContain(expectedConfig)
        val expectedAssertions = """
        let output = try await client.outputStream(input: input)

        // Verify the response events
        let events = try await SmithyTestUtil.EventStreamTestUtil.events(output.stream)
        try #require(events.count == 2)
        #expect(events[0] == TestEventStream.payloadevent(PayloadEvent(
            header: "bar",
            payload: PayloadStructure(
                structureMember: "baz"
            )
        ))
        )
        #expect(events[1] == TestEventStream.payloadevent(PayloadEvent(
            header: "qux"
        ))
        )
"""
        outputContents.shouldContainOnlyOnce(expectedAssertions)
    }

    @Test
    fun `it expects a received error event to be thrown`() {
        val expected = """
        await #expect(throws: ErrorEvent.self) {
            let output = try await client.outputStream(input: input)
            _ = try await SmithyTestUtil.EventStreamTestUtil.events(output.stream)
        }
"""
        outputContents.shouldContainOnlyOnce(expected)
    }

    @Test
    fun `it expects the modeled error for a failed initial response`() {
        val expectedResponse = """
        var body = Foundation.Data()
        body.append(Foundation.Data("{\"message\": \"foo\"}".utf8))
        let httpResponse = SmithyTestUtil.EventStreamTestUtil.httpResponse(
            statusCode: 500,
            headers: [
                "X-Amzn-Errortype": "ServiceError",
            ],
            body: body
        )
"""
        outputContents.shouldContainOnlyOnce(expectedResponse)
        outputContents.shouldContainOnlyOnce("await #expect(throws: ServiceError.self) {")
    }

    @Test
    fun `it verifies initial response members`() {
        val expected = """
        let body = Foundation.Data()
        let httpResponse = SmithyTestUtil.EventStreamTestUtil.httpResponse(
            statusCode: 200,
            headers: [
                "initial-member": "foo",
                "Content-Type": "application/vnd.amazon.eventstream",
            ],
            body: body
        )
"""
        outputContents.shouldContainOnlyOnce(expected)
        val expectedAssertions = """
        // Verify the initial response
        let expected = OutputStreamOutput(
            initialMember: "foo"
        )
        #expect(output.initialMember == expected.initialMember)
"""
        outputContents.shouldContainOnlyOnce(expectedAssertions)
    }
}
