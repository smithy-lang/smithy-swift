/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.model.Model
import software.amazon.smithy.model.knowledge.TopDownIndex
import software.amazon.smithy.model.node.Node
import software.amazon.smithy.model.node.ObjectNode
import software.amazon.smithy.model.shapes.CollectionShape
import software.amazon.smithy.model.shapes.MapShape
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.ShapeType
import software.amazon.smithy.model.shapes.StructureShape
import software.amazon.smithy.model.shapes.UnionShape
import software.amazon.smithy.model.traits.ErrorTrait
import software.amazon.smithy.model.traits.HttpLabelTrait
import software.amazon.smithy.protocol.traits.Rpcv2CborTrait
import software.amazon.smithy.protocoltests.traits.AppliesTo
import software.amazon.smithy.protocoltests.traits.eventstream.Event
import software.amazon.smithy.protocoltests.traits.eventstream.EventHeaderValue
import software.amazon.smithy.protocoltests.traits.eventstream.EventStreamTestCase
import software.amazon.smithy.protocoltests.traits.eventstream.EventStreamTestsTrait
import software.amazon.smithy.protocoltests.traits.eventstream.EventType
import software.amazon.smithy.rulesengine.traits.EndpointRuleSetTrait
import software.amazon.smithy.swift.codegen.ShapeValueGenerator
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.model.RecursiveShapeBoxer
import software.amazon.smithy.swift.codegen.model.expectShape
import software.amazon.smithy.swift.codegen.model.findStreamingMember
import software.amazon.smithy.swift.codegen.model.getTrait
import software.amazon.smithy.swift.codegen.model.hasTrait
import software.amazon.smithy.swift.codegen.model.toLowerCamelCase
import software.amazon.smithy.swift.codegen.model.toUpperCamelCase
import software.amazon.smithy.swift.codegen.supportsStreamingAndIsRPC
import software.amazon.smithy.swift.codegen.swiftmodules.FoundationTypes
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyEventStreamsAPITypes
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyHTTPAPITypes
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyTestUtilTypes
import software.amazon.smithy.swift.codegen.utils.SDKFileUtils
import java.time.Instant
import java.util.Base64
import java.util.TreeSet
import java.util.logging.Logger

/**
 * Generates client protocol tests from the `smithy.test#eventStreamTests` trait.
 *
 * Tests are generated using the Swift Testing framework, with one test suite per operation.
 *
 * For each test case:
 * - Request events, along with the initial request if specified, are serialized by sending them through the
 *   operation to a `ProtocolTestClient`.  The resulting HTTP request & event stream messages are then
 *   compared to the expected values.
 * - Response events, along with the initial response if specified, are encoded into a HTTP response that is
 *   returned to the operation by a `ProtocolResponseTestClient`.  The resulting output & events are then
 *   compared to the expected values.
 * - If the test case expects failure, the test asserts that an error, of the expected type if one is given,
 *   is thrown.
 *
 * See https://smithy.io/2.0/additional-specs/protocol-traits.html#eventstreamtests-trait
 */
class EventStreamTestGenerator(
    private val ctx: ProtocolGenerator.GenerationContext,
    // list of test IDs to ignore/skip
    private val testsToIgnore: Set<String> = setOf(),
    private val tagsToIgnore: Set<String> = setOf(),
) {
    @Suppress("ktlint:standard:property-naming")
    private val LOGGER = Logger.getLogger(javaClass.name)

    private val model: Model = RecursiveShapeBoxer.transform(ctx.model)
    private val clientName = "${ctx.settings.clientBaseName}Client"
    private val region = "us-west-2"

    /**
     * Generates the event stream tests for all operations in the service.
     *
     * @return the number of test cases generated.
     */
    fun generateEventStreamTests(): Int {
        val operations = TopDownIndex.of(ctx.model).getContainedOperations(ctx.service).filterNot { it.hasTag("server-only") }
        var numTests = 0
        for (operation in TreeSet(operations)) {
            val testCases = testCases(operation)
            if (testCases.isEmpty()) continue
            renderTestSuite(operation, testCases)
            numTests += testCases.size
        }
        return numTests
    }

    private fun testCases(operation: OperationShape): List<EventStreamTestCase> =
        operation
            .getTrait<EventStreamTestsTrait>()
            ?.getTestCasesFor(AppliesTo.CLIENT)
            .orEmpty()
            .filter { it.protocol == ctx.protocol }
            .filter { it.id !in testsToIgnore }
            .filter { testCase -> tagsToIgnore.none { testCase.tags.contains(it) } }

    private fun renderTestSuite(
        operation: OperationShape,
        testCases: List<EventStreamTestCase>,
    ) {
        val suiteName = "${operation.toUpperCamelCase()}EventStreamTests"
        val filename = SDKFileUtils(ctx.settings).testsDirFilePath(suiteName)
        ctx.delegator.useTestFileWriter(filename, ctx.settings.moduleName) { writer ->
            LOGGER.fine("Generating event stream test cases for ${operation.id}")
            writer.addImport(SwiftDependency.SWIFT_TESTING.target)
            writer.addImport(SwiftDependency.CLIENT_RUNTIME.target)
            writer.addImport(SwiftDependency.SMITHY_EVENT_STREAMS_API.target)
            writer.addImport(ctx.settings.moduleName, true)
            writer.addImport(SwiftDependency.SMITHY_TEST_UTIL.target)
            writer.write("")
            writer.write("@Suite")
            writer.openBlock("struct \$L {", "}", suiteName) {
                testCases.forEach { OperationTest(writer, operation, it).render() }
            }
        }
    }

    /**
     * Renders a single test function for one event stream test case.
     */
    private inner class OperationTest(
        val writer: SwiftWriter,
        val operation: OperationShape,
        val test: EventStreamTestCase,
    ) {
        val inputShape = model.expectShape<StructureShape>(operation.inputShape)
        val outputShape = model.expectShape<StructureShape>(operation.outputShape)
        val requestEvents = test.events.filter { it.type == EventType.REQUEST }
        val responseEvents = test.events.filter { it.type == EventType.RESPONSE }
        val initialRequest = test.initialRequest.orElse(null)
        val initialResponse = test.initialResponse.orElse(null)

        val hasRequestPhase =
            requestEvents.isNotEmpty() || initialRequest != null || test.initialRequestParams.isPresent
        val hasResponsePhase =
            responseEvents.isNotEmpty() || initialResponse != null || test.initialResponseParams.isPresent

        fun render() {
            writer.write("")
            test.documentation.ifPresent { writer.writeDocs(it) }
            if (!paramsAreRepresentable()) {
                writer.write(
                    "@Test(.disabled(\$L))",
                    swiftString("A value in this test is out of range for the Swift type that the SDK uses for it"),
                )
                writer.write("func test_\$L() async throws {}", test.id)
                return
            }
            val requestErrorEvents = requestEvents.filter { errorShape(inputShape, it) != null }
            if (requestErrorEvents.isNotEmpty() && (requestErrorEvents.size > 1 || requestEvents.last() != requestErrorEvents[0])) {
                // Swift event stream unions do not include error members; a client sends an error event by
                // finishing its event stream with the error.  So an error event can only be the last event.
                writer.write(
                    "@Test(.disabled(\$L))",
                    swiftString("A client can only send an error event as the last event on its event stream"),
                )
                writer.write("func test_\$L() async throws {}", test.id)
                return
            }
            writer.write("@Test")
            writer.openBlock("func test_\$L() async throws {", "}", test.id) {
                if (hasRequestPhase && hasResponsePhase) {
                    // Each phase is rendered in its own scope, so that each may declare its own client & input.
                    // The expectation of failure is applied to the response, since the response is where a
                    // client would observe a failure.
                    writer.openBlock("do {", "}") { renderRequestPhase(expectFailure = false) }
                    writer.openBlock("do {", "}") { renderResponsePhase() }
                } else if (hasRequestPhase) {
                    renderRequestPhase(expectFailure = test.expectation.isFailure)
                } else if (hasResponsePhase) {
                    renderResponsePhase()
                }
            }
        }

        // MARK: - Request

        private fun renderRequestPhase(expectFailure: Boolean) {
            writer.write("// Serialize the request & its events")
            renderConfigAndClient(
                httpClientEngine = writer.format("\$N()", SmithyTestUtilTypes.ProtocolTestClient),
                isResponse = false,
            )
            writer.write("")
            renderInput(test.initialRequestParams.orElse(Node.objectNode()), requestEvents.filter { it.params.isPresent })
            writer.write("")
            if (expectFailure) {
                // The SDK fails while sending the request or while encoding its events, which happens as the
                // body is read.  The body is read as raw data, so that the test's own decoding of the events
                // cannot be mistaken for the expected failure.
                renderExpectFailure(expectedErrorShape()) {
                    renderCaptureRequest()
                    writer.write("_ = try await request.body.readData()")
                }
                return
            }
            renderCaptureRequest()
            initialRequest?.let { renderInitialRequestAssertions(it) }
            // Only an input with an event stream sends events; otherwise the request body is not an event stream.
            if (inputShape.findStreamingMember(model) != null) {
                renderRequestEventAssertions()
            }
        }

        private fun renderCaptureRequest() {
            writer.openBlock("let request = try await \$N.captureRequest {", "}", SmithyTestUtilTypes.EventStreamTestUtil) {
                writer.write("_ = try await client.\$L(input: input)", operation.toLowerCamelCase())
            }
        }

        private fun renderInitialRequestAssertions(initialRequest: ObjectNode) {
            writer.write("")
            writer.write("// Verify the initial request")
            initialRequest.getStringMember("method").ifPresent {
                writer.write("#expect(request.method == .\$L)", it.value.lowercase())
            }
            initialRequest.getStringMember("uri").ifPresent {
                writer.write("#expect(request.path == \$L)", swiftString(it.value))
            }
            initialRequest.getStringMember("resolvedHost").ifPresent {
                writer.write("#expect(request.host == \$L)", swiftString(it.value))
            }
            // When the input has an event stream, the request body is the event stream & is verified as events.
            // Otherwise the initial request's body, if given, is the request body.
            if (inputShape.findStreamingMember(model) == null) {
                initialRequest.getStringMember("body").ifPresent { body ->
                    val mediaType = initialRequest.getStringMember("bodyMediaType").map { it.value }.orElse(null)
                    writer.write(
                        "#expect(try await \$N.payload(request.body.readData() ?? \$N(), matches: \$L, mediaType: \$L))",
                        SmithyTestUtilTypes.EventStreamTestUtil,
                        FoundationTypes.Data,
                        bodyData(body.value, mediaType),
                        mediaType?.let { swiftString(it) } ?: "nil",
                    )
                }
            }
            initialRequest.getObjectMember("headers").ifPresent { headers ->
                headers.stringMap.forEach { (name, value) ->
                    writer.write(
                        "#expect(request.headers.value(for: \$L) == \$L)",
                        swiftString(name),
                        swiftString(value.expectStringNode().value),
                    )
                }
            }
            stringList(initialRequest, "forbidHeaders").forEach {
                writer.write("#expect(!request.headers.exists(name: \$L))", swiftString(it))
            }
            stringList(initialRequest, "requireHeaders").forEach {
                writer.write("#expect(request.headers.exists(name: \$L))", swiftString(it))
            }
            stringList(initialRequest, "queryParams").forEach {
                writer.write(
                    "#expect(\$N.request(request, hasQueryItem: \$L))",
                    SmithyTestUtilTypes.EventStreamTestUtil,
                    swiftString(it),
                )
            }
            stringList(initialRequest, "forbidQueryParams").forEach {
                writer.write(
                    "#expect(!\$N.request(request, hasQueryItemNamed: \$L))",
                    SmithyTestUtilTypes.EventStreamTestUtil,
                    swiftString(it),
                )
            }
            stringList(initialRequest, "requireQueryParams").forEach {
                writer.write(
                    "#expect(\$N.request(request, hasQueryItemNamed: \$L))",
                    SmithyTestUtilTypes.EventStreamTestUtil,
                    swiftString(it),
                )
            }
        }

        private fun renderRequestEventAssertions() {
            // An initial-request message is sent before the events, so it is verified along with them.
            val events = requestEvents.filter { it.params.isPresent || it.isInitialMessage }
            writer.write("")
            writer.write("// Verify the request events")
            writer.write("let messages = try await \$N.messages(in: request)", SmithyTestUtilTypes.EventStreamTestUtil)
            writer.write("try #require(messages.count == \$L)", events.size)
            events.forEachIndexed { index, event ->
                val message = "messages[$index]"
                event.headers.toSortedMap().forEach { (name, value) ->
                    writer.write(
                        "#expect(\$L.headers.value(name: \$L) == \$L)",
                        message,
                        swiftString(name),
                        headerValue(value),
                    )
                }
                event.forbidHeaders.forEach {
                    writer.write("#expect(\$L.headers.value(name: \$L) == nil)", message, swiftString(it))
                }
                event.requireHeaders.forEach {
                    writer.write("#expect(\$L.headers.value(name: \$L) != nil)", message, swiftString(it))
                }
                event.body.ifPresent { body ->
                    val mediaType = event.bodyMediaType.orElse(null)
                    writer.write(
                        "#expect(try \$N.payload(\$L.payload, matches: \$L, mediaType: \$L))",
                        SmithyTestUtilTypes.EventStreamTestUtil,
                        message,
                        bodyData(body, mediaType),
                        mediaType?.let { swiftString(it) } ?: "nil",
                    )
                }
            }
        }

        // MARK: - Response

        private fun renderResponsePhase() {
            writer.write("// Deserialize the response & its events")
            renderHTTPResponse()
            writer.write("")
            renderConfigAndClient(
                httpClientEngine =
                    writer.format("\$N(httpResponse: httpResponse)", SmithyTestUtilTypes.ProtocolResponseTestClient),
                isResponse = true,
            )
            writer.write("")
            renderInput(responsePhaseInputParams(), listOf())
            writer.write("")
            val outputStreamMember = outputShape.findStreamingMember(model)
            // Swift event streams throw error events rather than yielding them, so a test that receives
            // an error event expects that error to be thrown.
            val errorEventShape = responseEvents.firstNotNullOfOrNull { errorShape(outputShape, it) }
            if (test.expectation.isFailure || errorEventShape != null) {
                renderExpectFailure(expectedErrorShape() ?: errorEventShape) {
                    writer.write("let output = try await client.\$L(input: input)", operation.toLowerCamelCase())
                    if (outputStreamMember != null) {
                        writer.write(
                            "_ = try await \$N.events(output.\$L)",
                            SmithyTestUtilTypes.EventStreamTestUtil,
                            ctx.symbolProvider.toMemberName(outputStreamMember),
                        )
                    } else {
                        writer.write("_ = output")
                    }
                }
                return
            }
            writer.write("let output = try await client.\$L(input: input)", operation.toLowerCamelCase())
            test.initialResponseParams.ifPresent { renderInitialResponseAssertions(it) }
            if (outputStreamMember != null) {
                renderResponseEventAssertions(outputStreamMember)
            }
        }

        private fun renderHTTPResponse() {
            val statusCode = initialResponse?.getNumberMember("code")?.map { it.value.toInt() }?.orElse(null) ?: 200
            val headers = linkedMapOf<String, String>()
            initialResponse?.getObjectMember("headers")?.ifPresent { node ->
                node.stringMap.forEach { (name, value) -> headers[name] = value.expectStringNode().value }
            }
            // Add any headers the protocol requires on every response, if the test didn't give them.
            protocolResponseHeaders().forEach { (name, value) ->
                if (headers.keys.none { it.equals(name, ignoreCase = true) }) headers[name] = value
            }
            val isSuccess = statusCode in 200..299
            if (isSuccess && headers.keys.none { it.equals("Content-Type", ignoreCase = true) }) {
                headers["Content-Type"] = "application/vnd.amazon.eventstream"
            }

            val bodyParts =
                if (responseEvents.isNotEmpty()) {
                    responseEvents.map { eventData(it) }
                } else {
                    listOfNotNull(
                        initialResponse
                            ?.getStringMember("body")
                            ?.map { body ->
                                val mediaType = initialResponse.getStringMember("bodyMediaType").map { it.value }.orElse(null)
                                bodyData(body.value, mediaType)
                            }?.orElse(null),
                    )
                }
            if (bodyParts.isEmpty()) {
                writer.write("let body = \$N()", FoundationTypes.Data)
            } else {
                writer.write("var body = \$N()", FoundationTypes.Data)
                bodyParts.forEach { writer.write("body.append(\$L)", it) }
            }
            writer.openBlock("let httpResponse = try \$N.httpResponse(", ")", SmithyTestUtilTypes.EventStreamTestUtil) {
                writer.write("statusCode: \$L,", statusCode)
                if (headers.isEmpty()) {
                    writer.write("headers: [:],")
                } else {
                    writer.openBlock("headers: [", "],") {
                        headers.forEach { (name, value) ->
                            writer.write("\$L: \$L,", swiftString(name), swiftString(value))
                        }
                    }
                }
                writer.write("body: body")
            }
        }

        private fun eventData(event: Event): String {
            val bytes = event.bytes.orElse(null)
            if (bytes != null) {
                return writer.format(
                    "\$N(base64Encoded: \$L)!",
                    FoundationTypes.Data,
                    swiftString(Base64.getEncoder().encodeToString(bytes)),
                )
            }
            // No binary representation of the event was given, so construct & encode one from its headers & body.
            val headers =
                event.headers.toSortedMap().entries.joinToString(", ") { (name, value) ->
                    writer.format("\$N(name: \$L, value: \$L)", SmithyEventStreamsAPITypes.Header, swiftString(name), headerValue(value))
                }
            val payload =
                event.body
                    .map { bodyData(it, event.bodyMediaType.orElse(null)) }
                    .orElse(writer.format("\$N()", FoundationTypes.Data))
            return writer.format(
                "try \$N.encode([\$N(headers: [\$L], payload: \$L)])",
                SmithyTestUtilTypes.EventStreamTestUtil,
                SmithyEventStreamsAPITypes.Message,
                headers,
                payload,
            )
        }

        private fun renderInitialResponseAssertions(params: ObjectNode) {
            writer.write("")
            writer.write("// Verify the initial response")
            writer.writeInline("let expected = ")
            ShapeValueGenerator(model, ctx.symbolProvider).writeShapeValueInline(writer, outputShape, params)
            writer.write("")
            params.members.keys.forEach { key ->
                val member = outputShape.getMember(key.value).orElse(null) ?: return@forEach
                val memberName = ctx.symbolProvider.toMemberName(member)
                writer.write("#expect(output.\$L == expected.\$L)", memberName, memberName)
            }
        }

        private fun renderResponseEventAssertions(streamMember: MemberShape) {
            writer.write("")
            writer.write("// Verify the response events")
            writer.write(
                "let events = try await \$N.events(output.\$L)",
                SmithyTestUtilTypes.EventStreamTestUtil,
                ctx.symbolProvider.toMemberName(streamMember),
            )
            // An initial-response message carries output members, not an event, so it is not on the event stream.
            val streamEvents = responseEvents.filterNot { it.isInitialMessage }
            // Events without params are unmodeled; their deserialized form is not specified, so the
            // events are only checked when all of them are modeled.
            if (streamEvents.any { !it.params.isPresent }) return
            writer.write("try #require(events.count == \$L)", streamEvents.size)
            val unionShape = model.expectShape(streamMember.target)
            streamEvents.forEachIndexed { index, event ->
                writer.writeInline("#expect(events[\$L] == ", index)
                ShapeValueGenerator(model, ctx.symbolProvider).writeShapeValueInline(writer, unionShape, event.params.get())
                writer.write(")")
            }
        }

        // MARK: - Shared

        /**
         * The error shape that the test expects to be thrown, if the test expects failure with a specific error.
         */
        private fun expectedErrorShape(): Shape? =
            test.expectation.failure
                .flatMap { it.errorId }
                .map { model.expectShape(it) }
                .orElse(null)

        /**
         * Renders code that expects the code rendered by [body] to throw.
         *
         * If an error shape is given, the error thrown must be of that type.  Otherwise any error thrown by the SDK
         * is accepted, but an error thrown by the test harness itself fails the test.
         */
        private fun renderExpectFailure(
            errorShape: Shape?,
            body: () -> Unit,
        ) {
            if (errorShape != null) {
                val errorSymbol = ctx.symbolProvider.toSymbol(errorShape)
                writer.openBlock("await #expect(throws: \$N.self) {", "}", errorSymbol) { body() }
            } else {
                writer.openBlock("let error = try await \$N.sdkError {", "}", SmithyTestUtilTypes.EventStreamTestUtil) { body() }
                writer.write("#expect(error != nil, \"Expected the SDK to throw an error\")")
            }
        }

        /**
         * Headers that the test's protocol requires on every HTTP response.
         */
        private fun protocolResponseHeaders(): Map<String, String> =
            when (test.protocol) {
                Rpcv2CborTrait.ID -> mapOf("smithy-protocol" to "rpc-v2-cbor")
                else -> mapOf()
            }

        /**
         * Whether every value in the test's params fits the Swift type that the SDK uses for it.
         *
         * Values that do not fit, i.e. a `BigInteger` beyond the range of `Int`, cannot be written as Swift literals.
         */
        private fun paramsAreRepresentable(): Boolean {
            val streamUnions =
                listOfNotNull(inputShape.findStreamingMember(model), outputShape.findStreamingMember(model))
                    .map { model.expectShape(it.target) }
            val paramsAndShapes =
                listOfNotNull(
                    test.initialRequestParams.orElse(null)?.let { it to inputShape },
                    test.initialResponseParams.orElse(null)?.let { it to outputShape },
                ) +
                    test.events.mapNotNull { event ->
                        val params = event.params.orElse(null) ?: return@mapNotNull null
                        val union = streamUnions.firstOrNull { union -> params.members.keys.all { union.getMember(it.value).isPresent } }
                        union?.let { params to it }
                    }
            return paramsAndShapes.all { (params, shape) -> isRepresentable(params, shape) }
        }

        private fun isRepresentable(
            node: Node,
            shape: Shape,
        ): Boolean =
            when {
                node.isNullNode -> true
                shape.isBigIntegerShape ->
                    node
                        .asNumberNode()
                        .map {
                            it.value.toString().toBigIntegerOrNull()?.bitLength()?.let { bits ->
                                bits < 64
                            } ?: true
                        }.orElse(true)
                shape is MemberShape -> isRepresentable(node, model.expectShape(shape.target))
                node.isObjectNode -> {
                    val members = node.expectObjectNode().members
                    when (shape) {
                        is StructureShape, is UnionShape ->
                            members.all { (key, value) ->
                                val member = shape.getMember(key.value).orElse(null)
                                member == null || isRepresentable(value, member)
                            }
                        is MapShape -> members.values.all { isRepresentable(it, shape.value) }
                        else -> true
                    }
                }
                node.isArrayNode && shape is CollectionShape -> node.expectArrayNode().elements.all { isRepresentable(it, shape.member) }
                else -> true
            }

        /**
         * Returns the error shape that the event targets, if the event is a modeled error on the event stream
         * of the passed input or output.  Returns `null` otherwise.
         */
        private fun errorShape(
            container: StructureShape,
            event: Event,
        ): Shape? {
            val streamMember = container.findStreamingMember(model) ?: return null
            val unionShape = model.expectShape<UnionShape>(streamMember.target)
            val memberName =
                event.params
                    .orElse(null)
                    ?.members
                    ?.keys
                    ?.firstOrNull()
                    ?.value ?: return null
            val member = unionShape.getMember(memberName).orElse(null) ?: return null
            return model.expectShape(member.target).takeIf { it.hasTrait<ErrorTrait>() }
        }

        private fun renderConfigAndClient(
            httpClientEngine: String,
            isResponse: Boolean,
        ) {
            writer.openBlock("let config = try await \$1L.\$1LConfig(", ")", clientName) {
                writer.write("awsCredentialIdentityResolver: try \$N(),", SmithyTestUtilTypes.dummyIdentityResolver)
                writer.write("region: \$S,", region)
                writer.write("signingRegion: \$S,", region)
                if (!ctx.service.hasTrait<EndpointRuleSetTrait>()) {
                    // The initial request's host, if given, is the host the client is configured with.
                    val host =
                        initialRequest
                            ?.getStringMember("host")
                            ?.map { it.value }
                            ?.orElse(null)
                            ?.takeIf { it.isNotEmpty() } ?: "example.com"
                    writer.write(
                        "endpointResolver: \$L.StaticEndpointResolver(endpoint: try \$N(urlString: \$L)),",
                        ctx.settings.moduleName,
                        SmithyHTTPAPITypes.Endpoint,
                        swiftString("https://$host"),
                    )
                }
                if (isResponse) {
                    writer.write("retryStrategyOptions: \$N.make(),", SmithyTestUtilTypes.ProtocolTestRetryStrategyOptions)
                } else {
                    writer.write("idempotencyTokenGenerator: \$N(),", SmithyTestUtilTypes.ProtocolTestIdempotencyTokenGenerator)
                }
                writer.write("httpClientEngine: \$L,", httpClientEngine)
                writer.write("httpInterceptorProviders: [\$N()]", SmithyTestUtilTypes.EventStreamTestInterceptorProvider)
            }
            writer.write("let client = \$L(config: config)", clientName)
        }

        /**
         * Renders the operation input from the passed params.  If the input has an event stream member,
         * the passed events are set on it.
         */
        private fun renderInput(
            params: ObjectNode,
            events: List<Event>,
        ) {
            val streamMember = inputShape.findStreamingMember(model)
            val keyword = if (streamMember != null) "var" else "let"
            writer.writeInline("$keyword input = ")
            ShapeValueGenerator(model, ctx.symbolProvider).writeShapeValueInline(writer, inputShape, params)
            writer.write("")
            if (streamMember == null) return
            val unionShape = model.expectShape(streamMember.target)
            val unionSymbol = ctx.symbolProvider.toSymbol(unionShape)
            // A modeled error is not a case of the Swift event stream enum; the stream finishes by throwing it instead.
            val errorEvent = events.lastOrNull()?.takeIf { errorShape(inputShape, it) != null }
            val modeledEvents = events.filter { it != errorEvent }
            if (modeledEvents.isEmpty()) {
                writer.write("let inputEvents = [\$N]()", unionSymbol)
            } else {
                writer.openBlock("let inputEvents: [\$N] = [", "]", unionSymbol) {
                    modeledEvents.forEach { event ->
                        ShapeValueGenerator(model, ctx.symbolProvider).writeShapeValueInline(writer, unionShape, event.params.get())
                        writer.write(",")
                    }
                }
            }
            val memberName = ctx.symbolProvider.toMemberName(streamMember)
            if (errorEvent != null) {
                val errorShape = errorShape(inputShape, errorEvent)!!
                val errorParams =
                    errorEvent.params
                        .get()
                        .members.values
                        .first()
                writer.writeInline("let inputError = ")
                ShapeValueGenerator(model, ctx.symbolProvider).writeShapeValueInline(writer, errorShape, errorParams)
                writer.write("")
                writer.write(
                    "input.\$L = \$N.stream(inputEvents, finishingWith: inputError)",
                    memberName,
                    SmithyTestUtilTypes.EventStreamTestUtil,
                )
            } else {
                writer.write("input.\$L = \$N.stream(inputEvents)", memberName, SmithyTestUtilTypes.EventStreamTestUtil)
            }
        }

        /**
         * The params used to create the input for the response phase.
         *
         * The initial request params are used if they were provided.  Any HTTP label members that are not
         * provided are given a placeholder value, so that a valid request can be constructed.
         */
        private fun responsePhaseInputParams(): ObjectNode {
            val builder = test.initialRequestParams.orElse(Node.objectNode()).toBuilder()
            val params = test.initialRequestParams.orElse(Node.objectNode())
            inputShape.members().filter { it.hasTrait<HttpLabelTrait>() }.forEach { member ->
                if (params.getMember(member.memberName).isPresent) return@forEach
                val placeholder: Node =
                    when (model.expectShape(member.target).type) {
                        ShapeType.STRING -> Node.from("test")
                        ShapeType.BOOLEAN -> Node.from(false)
                        ShapeType.TIMESTAMP -> Node.from(0)
                        else -> Node.from(0) // only other allowed types are numbers
                    }
                builder.withMember(member.memberName, placeholder)
            }
            return builder.build()
        }

        private fun headerValue(value: EventHeaderValue<*>): String =
            when (value.type) {
                EventHeaderValue.Type.BOOLEAN -> ".bool(${value.asBoolean()})"
                EventHeaderValue.Type.BYTE -> ".byte(${value.asByte()})"
                EventHeaderValue.Type.SHORT -> ".int16(${value.asShort()})"
                EventHeaderValue.Type.INTEGER -> ".int32(${value.asInteger()})"
                EventHeaderValue.Type.LONG -> ".int64(${value.asLong()})"
                EventHeaderValue.Type.BLOB ->
                    writer.format(
                        ".byteArray(\$N(base64Encoded: \$L)!)",
                        FoundationTypes.Data,
                        swiftString(Base64.getEncoder().encodeToString(value.asBlob())),
                    )
                EventHeaderValue.Type.STRING -> ".string(${swiftString(value.asString())})"
                EventHeaderValue.Type.TIMESTAMP ->
                    writer.format(
                        ".timestamp(\$N(timeIntervalSince1970: \$L))",
                        FoundationTypes.Date,
                        epochSeconds(value.asTimestamp()),
                    )
                null -> throw IllegalStateException("Event header value has no type")
            }

        /**
         * Renders a Swift expression for the `Data` of an event or response body.
         *
         * CBOR bodies are base64-encoded in the Smithy model; all other bodies are text.
         */
        private fun bodyData(
            body: String,
            mediaType: String?,
        ): String =
            if (mediaType?.lowercase()?.endsWith("cbor") == true) {
                writer.format("\$N(base64Encoded: \$L)!", FoundationTypes.Data, swiftString(body.trim()))
            } else {
                writer.format("\$N(\$L.utf8)", FoundationTypes.Data, swiftString(body))
            }
    }

    /**
     * Whether the event is an `initial-request` or `initial-response` message, which carries the members of the
     * input or output other than the event stream, rather than an event.
     *
     * Only RPC protocols send initial messages.  HTTP binding protocols (i.e. restJson1) bind all of those members
     * to the HTTP request or response, so on those protocols no event is an initial message.
     */
    private val Event.isInitialMessage: Boolean
        get() =
            supportsStreamingAndIsRPC(ctx.protocol) &&
                headers[":event-type"]
                    ?.takeIf { it.type == EventHeaderValue.Type.STRING }
                    ?.asString() in setOf("initial-request", "initial-response")

    private fun stringList(
        node: ObjectNode,
        name: String,
    ): List<String> =
        node
            .getArrayMember(name)
            .map { array -> array.elements.map { it.expectStringNode().value } }
            .orElse(listOf())
}

/**
 * Renders an [Instant] as seconds since the epoch, with millisecond precision, which is the precision
 * of event stream timestamp headers.
 */
private fun epochSeconds(instant: Instant): String {
    val millis = instant.toEpochMilli()
    val seconds = Math.floorDiv(millis, 1000L)
    val fraction = Math.floorMod(millis, 1000L)
    return "$seconds.${fraction.toString().padStart(3, '0')}"
}

/**
 * Renders a Kotlin string as a Swift string literal.
 */
internal fun swiftString(value: String): String {
    val builder = StringBuilder("\"")
    value.forEach { char ->
        when {
            char == '\\' -> builder.append("\\\\")
            char == '"' -> builder.append("\\\"")
            char == '\n' -> builder.append("\\n")
            char == '\r' -> builder.append("\\r")
            char == '\t' -> builder.append("\\t")
            char.code < 0x20 || char.code == 0x7F -> builder.append("\\u{${Integer.toHexString(char.code)}}")
            else -> builder.append(char)
        }
    }
    return builder.append("\"").toString()
}
