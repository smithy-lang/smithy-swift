//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import ClientRuntime
import SmithyJSON

class OrchestratorTests: XCTestCase {
    struct TestInput {
        let foo: String
    }

    struct TestOutput: Equatable {
        let bar: String
    }

    struct TestBaseError: BaseError {
        var code: String { "TestBaseError" }
        let message: String? = nil
        let requestID: String? = nil
        public var errorBodyReader: Reader { responseReader }

        public let httpResponse: HttpResponse
        private let responseReader: Reader

        public init(httpResponse: HttpResponse, responseReader: Reader, noErrorWrapping: Bool) throws {
            self.httpResponse = httpResponse
            self.responseReader = responseReader
        }
    }

    struct TestError: Error, Equatable, LocalizedError {
        let value: String

        public var errorDescription: String? {
            value
        }
    }

    // Reference type wrapper for an array
    class Trace {
        var trace: [String] = []

        func append(_ thing: String) {
            self.trace.append(thing)
        }
    }

    class TraceLogger: LogAgent {
        var trace: Trace = Trace()
        var name: String = "TestTraceLogger"
        var level: LogAgentLevel = .debug

        func log(level: LogAgentLevel, message: String, metadata: [String : String]?, source: String, file: String, function: String, line: UInt) {
            trace.append(message)
        }
    }

    class TraceInterceptor<InputType, OutputType, RequestType: RequestMessage, ResponseType: ResponseMessage, AttributesType: HasAttributes>:
        Interceptor
    {
        var trace: Trace

        init(trace: Trace) {
            self.trace = trace
        }

        public func readBeforeExecution(context: some BeforeSerialization<InputType, AttributesType>) async throws {
            trace.append("readBeforeExecution")
        }

        public func modifyBeforeSerialization(context: some MutableInput<InputType, AttributesType>) async throws {
            trace.append("modifyBeforeSerialization")
        }

        public func readBeforeSerialization(context: some BeforeSerialization<InputType, AttributesType>) async throws {
            trace.append("readBeforeSerialization")
        }

        public func readAfterSerialization(context: some AfterSerialization<InputType, RequestType, AttributesType>) async throws {
            trace.append("readAfterSerialization")
        }

        public func modifyBeforeRetryLoop(context: some MutableRequest<InputType, RequestType, AttributesType>) async throws {
            trace.append("modifyBeforeRetryLoop")
        }

        public func readBeforeAttempt(context: some AfterSerialization<InputType, RequestType, AttributesType>) async throws {
            trace.append("readBeforeAttempt")
        }

        public func modifyBeforeSigning(context: some MutableRequest<InputType, RequestType, AttributesType>) async throws {
            trace.append("modifyBeforeSigning")
        }

        public func readBeforeSigning(context: some AfterSerialization<InputType, RequestType, AttributesType>) async throws {
            trace.append("readBeforeSigning")
        }

        public func readAfterSigning(context: some AfterSerialization<InputType, RequestType, AttributesType>) async throws {
            trace.append("readAfterSigning")
        }

        public func modifyBeforeTransmit(context: some MutableRequest<InputType, RequestType, AttributesType>) async throws {
            trace.append("modifyBeforeTransmit")
        }

        public func readBeforeTransmit(context: some AfterSerialization<InputType, RequestType, AttributesType>) async throws {
            trace.append("readBeforeTransmit")
        }

        public func readAfterTransmit(
            context: some BeforeDeserialization<InputType, RequestType, ResponseType, AttributesType>
        ) async throws {
            trace.append("readAfterTransmit")
        }

        public func modifyBeforeDeserialization(
            context: some MutableResponse<InputType, RequestType, ResponseType, AttributesType>
        ) async throws {
            trace.append("modifyBeforeDeserialization")
        }

        public func readBeforeDeserialization(
            context: some BeforeDeserialization<InputType, RequestType, ResponseType, AttributesType>
        ) async throws {
            trace.append("readBeforeDeserialization")
        }

        public func readAfterDeserialization(
            context: some AfterDeserialization<InputType, OutputType, RequestType, ResponseType, AttributesType>
        ) async throws {
            trace.append("readAfterDeserialization")
        }

        public func modifyBeforeAttemptCompletion(
            context: some MutableOutputAfterAttempt<InputType, OutputType, RequestType, ResponseType, AttributesType>
        ) async throws {
            trace.append("modifyBeforeAttemptCompletion")
        }

        public func readAfterAttempt(context: some AfterAttempt<InputType, OutputType, RequestType, ResponseType, AttributesType>) async throws
        {
            trace.append("readAfterAttempt")
        }

        public func modifyBeforeCompletion(
            context: some MutableOutputFinalization<InputType, OutputType, RequestType, ResponseType, AttributesType>
        ) async throws {
            trace.append("modifyBeforeCompletion")
        }

        public func readAfterExecution(
            context: some Finalization<InputType, OutputType, RequestType, ResponseType, AttributesType>
        ) async throws {
            trace.append("readAfterExecution")
        }
    }

    class TraceExecuteRequest: ExecuteRequest {
        var succeedAfter: Int
        var trace: Trace

        init(succeedAfter: Int = 0, trace: Trace) {
            self.succeedAfter = succeedAfter
            self.trace = trace
        }

        public func execute(request: SdkHttpRequest, attributes: HttpContext) async throws -> HttpResponse {
            trace.append("executeRequest")
            if succeedAfter <= 0 {
                return HttpResponse(body: request.body, statusCode: .ok)
            } else {
                succeedAfter -= 1
                return HttpResponse(body: request.body, statusCode: .internalServerError)
            }
        }
    }

    struct ThrowingRetryStrategy: RetryStrategy {
        init(options: ClientRuntime.RetryStrategyOptions) {}

        public func acquireInitialRetryToken(tokenScope: String) async throws -> DefaultRetryToken {
            throw TestError(value: "1")
        }

        public func refreshRetryTokenForRetry(tokenToRenew: DefaultRetryToken, errorInfo: RetryErrorInfo) async throws {
        }
        public func recordSuccess(token: DefaultRetryToken) async {}
    }

    func traceOrchestrator(
        trace: Trace
    ) -> OrchestratorBuilder<TestInput, TestOutput, SdkHttpRequest, HttpResponse, HttpContext> {
        let attributes = HttpContextBuilder()
            .withMethod(value: .get)
            .withPath(value: "/")
            .withOperation(value: "Test")
            .build()
        let traceInterceptor = TraceInterceptor<TestInput, TestOutput, SdkHttpRequest, HttpResponse, HttpContext>(trace: trace)
        let builder = OrchestratorBuilder<TestInput, TestOutput, SdkHttpRequest, HttpResponse, HttpContext>()
            .attributes(attributes)
            .serialize({ input, builder, _ in
                trace.append("serialize")
                builder.withMethod(.get)
                    .withPath("/")
                    .withHost("localhost")
                    .withBody(.data(try! JSONEncoder().encode(input.foo)))
            })
            .deserialize({ response, _ in
                trace.append("deserialize")
                if (200..<300).contains(response.statusCode.rawValue) {
                    guard case let .data(data) = response.body else {
                        return .success(TestOutput(bar: ""))
                    }
                    let bar = try! JSONDecoder().decode(String.self, from: data!)
                    return .success(TestOutput(bar: bar))
                } else {
                    let responseReader = try SmithyJSON.Reader.from(data: try await response.data())
                    let baseError = try TestBaseError(httpResponse: response, responseReader: responseReader, noErrorWrapping: true)
                    return .failure(try UnknownHTTPServiceError.makeError(baseError: baseError))
                }
            })
            .retryStrategy(DefaultRetryStrategy(options: RetryStrategyOptions()))
            .retryErrorInfoProvider({ e in
                trace.append("errorInfo")
                return DefaultRetryErrorInfoProvider.errorInfo(for: e)
            })
            .selectAuthScheme({ _ in
                trace.append("selectAuthScheme")
                return nil
            })
            .applyEndpoint({ request, _, _ in
                trace.append("applyEndpoint")
                return request
            })
            .applySigner({ request, _, _ in
                trace.append("applySigner")
                return request
            })
            .executeRequest(TraceExecuteRequest(trace: trace))
        builder.interceptors.add(traceInterceptor)
        return builder
    }

    func test_fullExecution() async throws {
        let orchestrator = traceOrchestrator(trace: Trace()).build()
        let output = try await orchestrator.execute(input: TestInput(foo: "foo"))

        XCTAssertEqual(output.bar, "foo")
    }

    func test_runsStepsInOrder() async throws {
        let trace = Trace()
        let orchestrator = traceOrchestrator(trace: trace).build()
        let output = try await orchestrator.execute(input: TestInput(foo: "foo"))

        XCTAssertEqual(output.bar, "foo")
        XCTAssertEqual(
            trace.trace,
            [
                "readBeforeExecution",
                "modifyBeforeSerialization",
                "readBeforeSerialization",
                "serialize",
                "readAfterSerialization",
                "modifyBeforeRetryLoop",
                "readBeforeAttempt",
                "selectAuthScheme",
                "applyEndpoint",
                "modifyBeforeSigning",
                "readBeforeSigning",
                "applySigner",
                "readAfterSigning",
                "modifyBeforeTransmit",
                "readBeforeTransmit",
                "executeRequest",
                "readAfterTransmit",
                "modifyBeforeDeserialization",
                "readBeforeDeserialization",
                "deserialize",
                "readAfterDeserialization",
                "modifyBeforeAttemptCompletion",
                "readAfterAttempt",
                "modifyBeforeCompletion",
                "readAfterExecution",
            ]
        )
    }

    func test_retryStepsOrder() async throws {
        let trace = Trace()
        let orchestrator = traceOrchestrator(trace: trace)
            .executeRequest(TraceExecuteRequest(succeedAfter: 1, trace: trace))
            .build()
        let output = try await orchestrator.execute(input: TestInput(foo: "foo"))

        XCTAssertEqual(
            trace.trace,
            [
                "readBeforeExecution",
                "modifyBeforeSerialization",
                "readBeforeSerialization",
                "serialize",
                "readAfterSerialization",
                "modifyBeforeRetryLoop",
                // attempt 1
                "readBeforeAttempt",
                "selectAuthScheme",
                "applyEndpoint",
                "modifyBeforeSigning",
                "readBeforeSigning",
                "applySigner",
                "readAfterSigning",
                "modifyBeforeTransmit",
                "readBeforeTransmit",
                "executeRequest",
                "readAfterTransmit",
                "modifyBeforeDeserialization",
                "readBeforeDeserialization",
                "deserialize",
                "readAfterDeserialization",
                "modifyBeforeAttemptCompletion",
                "readAfterAttempt",
                "errorInfo",
                // attempt 2
                "readBeforeAttempt",
                "selectAuthScheme",
                "applyEndpoint",
                "modifyBeforeSigning",
                "readBeforeSigning",
                "applySigner",
                "readAfterSigning",
                "modifyBeforeTransmit",
                "readBeforeTransmit",
                "executeRequest",
                // succeeded
                "readAfterTransmit",
                "modifyBeforeDeserialization",
                "readBeforeDeserialization",
                "deserialize",
                "readAfterDeserialization",
                "modifyBeforeAttemptCompletion",
                "readAfterAttempt",
                "modifyBeforeCompletion",
                "readAfterExecution",
            ]
        )
        XCTAssertEqual(output.bar, "foo")
    }

    func test_stepErrorHandlingReadBeforeExecution() async {
        let readBeforeExecutionTrace = Trace()
        let readBeforeExecution = await asyncResult {
            let b = self.traceOrchestrator(trace: readBeforeExecutionTrace)
            b.interceptors.addReadBeforeExecution({ _ in throw TestError(value: "1") })
            b.interceptors.addReadBeforeExecution({ _ in throw TestError(value: "2") })
            return try await b.build().execute(input: TestInput(foo: ""))
        }
        XCTAssertEqual(readBeforeExecution, .failure(TestError(value: "2")))
        XCTAssertEqual(
            readBeforeExecutionTrace.trace,
            [
                "readBeforeExecution",
                "modifyBeforeCompletion",
                "readAfterExecution",
            ]
        )
    }

    func test_stepErrorHandlingModifyBeforeSerialization() async {
        let modifyBeforeSerializationTrace = Trace()
        let modifyBeforeSerialization = await asyncResult {
            let b = self.traceOrchestrator(trace: modifyBeforeSerializationTrace)
            b.interceptors.addModifyBeforeSerialization({ _ in throw TestError(value: "1") })
            b.interceptors.addModifyBeforeSerialization({ _ in throw TestError(value: "2") })
            return try await b.build().execute(input: TestInput(foo: ""))
        }
        XCTAssertEqual(modifyBeforeSerialization, .failure(TestError(value: "2")))
        XCTAssertEqual(
            modifyBeforeSerializationTrace.trace,
            [
                "readBeforeExecution",
                "modifyBeforeSerialization",
                "modifyBeforeCompletion",
                "readAfterExecution",
            ]
        )
    }

    func test_stepErrorHandlingReadBeforeSerialization() async {
        let readBeforeSerializationTrace = Trace()
        let readBeforeSerialization = await asyncResult {
            let b = self.traceOrchestrator(trace: readBeforeSerializationTrace)
            b.interceptors.addReadBeforeSerialization({ _ in throw TestError(value: "1") })
            b.interceptors.addReadBeforeSerialization({ _ in throw TestError(value: "2") })
            return try await b.build().execute(input: TestInput(foo: ""))
        }

        XCTAssertEqual(readBeforeSerialization, .failure(TestError(value: "2")))
        XCTAssertEqual(
            readBeforeSerializationTrace.trace,
            [
                "readBeforeExecution",
                "modifyBeforeSerialization",
                "readBeforeSerialization",
                "modifyBeforeCompletion",
                "readAfterExecution",
            ]
        )
    }

    func test_stepErrorHandlingSerialize() async {
        let serializeTrace = Trace()
        let serialize = await asyncResult {
            return try await self.traceOrchestrator(trace: serializeTrace)
                .serialize({ _, _, _ in throw TestError(value: "2") })
                .build()
                .execute(input: TestInput(foo: ""))
        }

        XCTAssertEqual(serialize, .failure(TestError(value: "2")))
        XCTAssertEqual(
            serializeTrace.trace,
            [
                "readBeforeExecution",
                "modifyBeforeSerialization",
                "readBeforeSerialization",
                "serialize",
                "modifyBeforeCompletion",
                "readAfterExecution",
            ]
        )
    }

    func test_stepErrorHandlingReadAfterSerialization() async {
        let readAfterSerializationTrace = Trace()
        let readAfterSerialization = await asyncResult {
            let b = self.traceOrchestrator(trace: readAfterSerializationTrace)
            b.interceptors.addReadAfterSerialization({ _ in throw TestError(value: "1") })
            b.interceptors.addReadAfterSerialization({ _ in throw TestError(value: "2") })
            return try await b.build().execute(input: TestInput(foo: ""))
        }

        XCTAssertEqual(readAfterSerialization, .failure(TestError(value: "2")))
        XCTAssertEqual(
            readAfterSerializationTrace.trace,
            [
                "readBeforeExecution",
                "modifyBeforeSerialization",
                "readBeforeSerialization",
                "serialize",
                "readAfterSerialization",
                "modifyBeforeCompletion",
                "readAfterExecution",
            ]
        )
    }

    func test_stepErrorHandlingModifyBeforeRetryLoop() async {
        let modifyBeforeRetryLoopTrace = Trace()
        let modifyBeforeRetryLoop = await asyncResult {
            let b = self.traceOrchestrator(trace: modifyBeforeRetryLoopTrace)
            b.interceptors.addModifyBeforeRetryLoop({ _ in throw TestError(value: "1") })
            b.interceptors.addModifyBeforeRetryLoop({ _ in throw TestError(value: "2") })
            return try await b.build().execute(input: TestInput(foo: ""))
        }

        XCTAssertEqual(modifyBeforeRetryLoop, .failure(TestError(value: "2")))
        XCTAssertEqual(
            modifyBeforeRetryLoopTrace.trace,
            [
                "readBeforeExecution",
                "modifyBeforeSerialization",
                "readBeforeSerialization",
                "serialize",
                "readAfterSerialization",
                "modifyBeforeRetryLoop",
                "modifyBeforeCompletion",
                "readAfterExecution",
            ]
        )
    }

    func test_stepErrorHandlingPartitionId() async {
        let partitionIdTrace = Trace()
        let partitionId = await asyncResult {
            let b = self.traceOrchestrator(trace: partitionIdTrace)
            // We can force a getPartitionId to fail by explicitly setting the host to ''
            b.interceptors.addModifyBeforeRetryLoop({ context in
                context.updateRequest(updated: context.getRequest().toBuilder().withHost("").build())
            })
            return try await b.build().execute(input: TestInput(foo: ""))
        }

        if case .success = partitionId {
            XCTFail("Expected getting partitionId in Orchestrator to throw")
        }
        XCTAssertEqual(
            partitionIdTrace.trace,
            [
                "readBeforeExecution",
                "modifyBeforeSerialization",
                "readBeforeSerialization",
                "serialize",
                "readAfterSerialization",
                "modifyBeforeRetryLoop",
                "modifyBeforeCompletion",
                "readAfterExecution",
            ]
        )
    }

    func test_stepErrorHandlingInitialToken() async {
        let initialTokenTrace = Trace()
        let initialToken = await asyncResult {
            return try await self.traceOrchestrator(trace: initialTokenTrace)
                .retryStrategy(ThrowingRetryStrategy(options: RetryStrategyOptions()))
                .build()
                .execute(input: TestInput(foo: ""))
        }

        XCTAssertEqual(initialToken, .failure(TestError(value: "1")))
        XCTAssertEqual(
            initialTokenTrace.trace,
            [
                "readBeforeExecution",
                "modifyBeforeSerialization",
                "readBeforeSerialization",
                "serialize",
                "readAfterSerialization",
                "modifyBeforeRetryLoop",
                "modifyBeforeCompletion",
                "readAfterExecution",
            ]
        )
    }

    func test_stepErrorHandlingReadBeforeAttempt() async {
        let readBeforeAttemptTrace = Trace()
        let readBeforeAttempt = await asyncResult {
            let b = self.traceOrchestrator(trace: readBeforeAttemptTrace)
            b.interceptors.addReadBeforeAttempt({ _ in throw TestError(value: "1") })
            b.interceptors.addReadBeforeAttempt({ _ in throw TestError(value: "2") })
            return try await b.build().execute(input: TestInput(foo: ""))
        }

        XCTAssertEqual(readBeforeAttempt, .failure(TestError(value: "2")))
        XCTAssertEqual(
            readBeforeAttemptTrace.trace,
            [
                "readBeforeExecution",
                "modifyBeforeSerialization",
                "readBeforeSerialization",
                "serialize",
                "readAfterSerialization",
                "modifyBeforeRetryLoop",
                "readBeforeAttempt",
                "modifyBeforeAttemptCompletion",
                "readAfterAttempt",
                "errorInfo",
                "modifyBeforeCompletion",
                "readAfterExecution",
            ]
        )
    }

    func test_stepErrorHandlingSelectAuthScheme() async {
        let trace = Trace()
        let result = await asyncResult {
            return try await self.traceOrchestrator(trace: trace)
                .selectAuthScheme { _ in
                    trace.append("selectAuthScheme")
                    throw TestError(value: "1")
                }
                .build()
                .execute(input: TestInput(foo: ""))
        }

        XCTAssertEqual(result, .failure(TestError(value: "1")))
        XCTAssertEqual(
            trace.trace,
            [
                "readBeforeExecution",
                "modifyBeforeSerialization",
                "readBeforeSerialization",
                "serialize",
                "readAfterSerialization",
                "modifyBeforeRetryLoop",
                "readBeforeAttempt",
                "selectAuthScheme",
                "modifyBeforeAttemptCompletion",
                "readAfterAttempt",
                "errorInfo",
                "modifyBeforeCompletion",
                "readAfterExecution",
            ]
        )
    }

    func test_stepErrorHandlingApplyEndpoint() async {
        let trace = Trace()
        let result = await asyncResult {
            return try await self.traceOrchestrator(trace: trace)
                .applyEndpoint { _, _, _ in
                    trace.append("applyEndpoint")
                    throw TestError(value: "1")
                }
                .build()
                .execute(input: TestInput(foo: ""))
        }

        XCTAssertEqual(result, .failure(TestError(value: "1")))
        XCTAssertEqual(
            trace.trace,
            [
                "readBeforeExecution",
                "modifyBeforeSerialization",
                "readBeforeSerialization",
                "serialize",
                "readAfterSerialization",
                "modifyBeforeRetryLoop",
                "readBeforeAttempt",
                "selectAuthScheme",
                "applyEndpoint",
                "modifyBeforeAttemptCompletion",
                "readAfterAttempt",
                "errorInfo",
                "modifyBeforeCompletion",
                "readAfterExecution",
            ]
        )
    }

    func test_stepErrorHandlingModifyBeforeSigning() async {
        let modifyBeforeSigningTrace = Trace()
        let modifyBeforeSigning = await asyncResult {
            let b = self.traceOrchestrator(trace: modifyBeforeSigningTrace)
            b.interceptors.addModifyBeforeSigning({ _ in throw TestError(value: "1") })
            b.interceptors.addModifyBeforeSigning({ _ in throw TestError(value: "2") })
            return try await b.build().execute(input: TestInput(foo: ""))
        }

        XCTAssertEqual(modifyBeforeSigning, .failure(TestError(value: "2")))
        XCTAssertEqual(
            modifyBeforeSigningTrace.trace,
            [
                "readBeforeExecution",
                "modifyBeforeSerialization",
                "readBeforeSerialization",
                "serialize",
                "readAfterSerialization",
                "modifyBeforeRetryLoop",
                "readBeforeAttempt",
                "selectAuthScheme",
                "applyEndpoint",
                "modifyBeforeSigning",
                "modifyBeforeAttemptCompletion",
                "readAfterAttempt",
                "errorInfo",
                "modifyBeforeCompletion",
                "readAfterExecution",
            ]
        )
    }

    func test_stepErrorHandlingReadBeforeSigning() async {
        let readBeforeSigningTrace = Trace()
        let readBeforeSigning = await asyncResult {
            let b = self.traceOrchestrator(trace: readBeforeSigningTrace)
            b.interceptors.addReadBeforeSigning({ _ in throw TestError(value: "1") })
            b.interceptors.addReadBeforeSigning({ _ in throw TestError(value: "2") })
            return try await b.build().execute(input: TestInput(foo: ""))
        }

        XCTAssertEqual(readBeforeSigning, .failure(TestError(value: "2")))
        XCTAssertEqual(
            readBeforeSigningTrace.trace,
            [
                "readBeforeExecution",
                "modifyBeforeSerialization",
                "readBeforeSerialization",
                "serialize",
                "readAfterSerialization",
                "modifyBeforeRetryLoop",
                "readBeforeAttempt",
                "selectAuthScheme",
                "applyEndpoint",
                "modifyBeforeSigning",
                "readBeforeSigning",
                "modifyBeforeAttemptCompletion",
                "readAfterAttempt",
                "errorInfo",
                "modifyBeforeCompletion",
                "readAfterExecution",
            ]
        )
    }

    func test_stepErrorHandlingApplySigner() async {
        let trace = Trace()
        let result = await asyncResult {
            return try await self.traceOrchestrator(trace: trace)
                .applySigner { _, _, _ in
                    trace.append("applySigner")
                    throw TestError(value: "1")
                }
                .build()
                .execute(input: TestInput(foo: ""))
        }

        XCTAssertEqual(result, .failure(TestError(value: "1")))
        XCTAssertEqual(
            trace.trace,
            [
                "readBeforeExecution",
                "modifyBeforeSerialization",
                "readBeforeSerialization",
                "serialize",
                "readAfterSerialization",
                "modifyBeforeRetryLoop",
                "readBeforeAttempt",
                "selectAuthScheme",
                "applyEndpoint",
                "modifyBeforeSigning",
                "readBeforeSigning",
                "applySigner",
                "modifyBeforeAttemptCompletion",
                "readAfterAttempt",
                "errorInfo",
                "modifyBeforeCompletion",
                "readAfterExecution",
            ]
        )
    }

    func test_stepErrorHandlingReadAfterSigning() async {
        let readAfterSigningTrace = Trace()
        let readAfterSigning = await asyncResult {
            let b = self.traceOrchestrator(trace: readAfterSigningTrace)
            b.interceptors.addReadAfterSigning({ _ in throw TestError(value: "1") })
            b.interceptors.addReadAfterSigning({ _ in throw TestError(value: "2") })
            return try await b.build().execute(input: TestInput(foo: ""))
        }

        XCTAssertEqual(readAfterSigning, .failure(TestError(value: "2")))
        XCTAssertEqual(
            readAfterSigningTrace.trace,
            [
                "readBeforeExecution",
                "modifyBeforeSerialization",
                "readBeforeSerialization",
                "serialize",
                "readAfterSerialization",
                "modifyBeforeRetryLoop",
                "readBeforeAttempt",
                "selectAuthScheme",
                "applyEndpoint",
                "modifyBeforeSigning",
                "readBeforeSigning",
                "applySigner",
                "readAfterSigning",
                "modifyBeforeAttemptCompletion",
                "readAfterAttempt",
                "errorInfo",
                "modifyBeforeCompletion",
                "readAfterExecution",
            ]
        )
    }

    func test_stepErrorHandlingModifyBeforeTransmit() async {
        let modifyBeforeTransmitTrace = Trace()
        let modifyBeforeTransmit = await asyncResult {
            let b = self.traceOrchestrator(trace: modifyBeforeTransmitTrace)
            b.interceptors.addModifyBeforeTransmit({ _ in throw TestError(value: "1") })
            b.interceptors.addModifyBeforeTransmit({ _ in throw TestError(value: "2") })
            return try await b.build().execute(input: TestInput(foo: ""))
        }

        XCTAssertEqual(modifyBeforeTransmit, .failure(TestError(value: "2")))
        XCTAssertEqual(
            modifyBeforeTransmitTrace.trace,
            [
                "readBeforeExecution",
                "modifyBeforeSerialization",
                "readBeforeSerialization",
                "serialize",
                "readAfterSerialization",
                "modifyBeforeRetryLoop",
                "readBeforeAttempt",
                "selectAuthScheme",
                "applyEndpoint",
                "modifyBeforeSigning",
                "readBeforeSigning",
                "applySigner",
                "readAfterSigning",
                "modifyBeforeTransmit",
                "modifyBeforeAttemptCompletion",
                "readAfterAttempt",
                "errorInfo",
                "modifyBeforeCompletion",
                "readAfterExecution",
            ]
        )
    }

    func test_stepErrorHandlingReadBeforeTransmit() async {
        let readBeforeTransmitTrace = Trace()
        let readBeforeTransmit = await asyncResult {
            let b = self.traceOrchestrator(trace: readBeforeTransmitTrace)
            b.interceptors.addReadBeforeTransmit({ _ in throw TestError(value: "1") })
            b.interceptors.addReadBeforeTransmit({ _ in throw TestError(value: "2") })
            return try await b.build().execute(input: TestInput(foo: ""))
        }

        XCTAssertEqual(readBeforeTransmit, .failure(TestError(value: "2")))
        XCTAssertEqual(
            readBeforeTransmitTrace.trace,
            [
                "readBeforeExecution",
                "modifyBeforeSerialization",
                "readBeforeSerialization",
                "serialize",
                "readAfterSerialization",
                "modifyBeforeRetryLoop",
                "readBeforeAttempt",
                "selectAuthScheme",
                "applyEndpoint",
                "modifyBeforeSigning",
                "readBeforeSigning",
                "applySigner",
                "readAfterSigning",
                "modifyBeforeTransmit",
                "readBeforeTransmit",
                "modifyBeforeAttemptCompletion",
                "readAfterAttempt",
                "errorInfo",
                "modifyBeforeCompletion",
                "readAfterExecution",
            ]
        )
    }

    func test_stepErrorHandlingExecuteRequest() async {
        let trace = Trace()
        let result = await asyncResult {
            return try await self.traceOrchestrator(trace: trace)
                .executeRequest { _, _ in
                    trace.append("executeRequest")
                    throw TestError(value: "1")
                }
                .build()
                .execute(input: TestInput(foo: ""))
        }

        XCTAssertEqual(result, .failure(TestError(value: "1")))
        XCTAssertEqual(
            trace.trace,
            [
                "readBeforeExecution",
                "modifyBeforeSerialization",
                "readBeforeSerialization",
                "serialize",
                "readAfterSerialization",
                "modifyBeforeRetryLoop",
                "readBeforeAttempt",
                "selectAuthScheme",
                "applyEndpoint",
                "modifyBeforeSigning",
                "readBeforeSigning",
                "applySigner",
                "readAfterSigning",
                "modifyBeforeTransmit",
                "readBeforeTransmit",
                "executeRequest",
                "modifyBeforeAttemptCompletion",
                "readAfterAttempt",
                "errorInfo",
                "modifyBeforeCompletion",
                "readAfterExecution",
            ]
        )
    }

    func test_stepErrorHandlingReadAfterTransmit() async {
        let readAfterTransmitTrace = Trace()
        let readAfterTransmit = await asyncResult {
            let b = self.traceOrchestrator(trace: readAfterTransmitTrace)
            b.interceptors.addReadAfterTransmit({ _ in throw TestError(value: "1") })
            b.interceptors.addReadAfterTransmit({ _ in throw TestError(value: "2") })
            return try await b.build().execute(input: TestInput(foo: ""))
        }

        XCTAssertEqual(readAfterTransmit, .failure(TestError(value: "2")))
        XCTAssertEqual(
            readAfterTransmitTrace.trace,
            [
                "readBeforeExecution",
                "modifyBeforeSerialization",
                "readBeforeSerialization",
                "serialize",
                "readAfterSerialization",
                "modifyBeforeRetryLoop",
                "readBeforeAttempt",
                "selectAuthScheme",
                "applyEndpoint",
                "modifyBeforeSigning",
                "readBeforeSigning",
                "applySigner",
                "readAfterSigning",
                "modifyBeforeTransmit",
                "readBeforeTransmit",
                "executeRequest",
                "readAfterTransmit",
                "modifyBeforeAttemptCompletion",
                "readAfterAttempt",
                "errorInfo",
                "modifyBeforeCompletion",
                "readAfterExecution",
            ]
        )
    }

    func test_stepErrorHandlingModifyBeforeDeserialization() async {
        let modifyBeforeDeserializationTrace = Trace()
        let modifyBeforeDeserialization = await asyncResult {
            let b = self.traceOrchestrator(trace: modifyBeforeDeserializationTrace)
            b.interceptors.addModifyBeforeDeserialization({ _ in throw TestError(value: "1") })
            b.interceptors.addModifyBeforeDeserialization({ _ in throw TestError(value: "2") })
            return try await b.build().execute(input: TestInput(foo: ""))
        }

        XCTAssertEqual(modifyBeforeDeserialization, .failure(TestError(value: "2")))
        XCTAssertEqual(
            modifyBeforeDeserializationTrace.trace,
            [
                "readBeforeExecution",
                "modifyBeforeSerialization",
                "readBeforeSerialization",
                "serialize",
                "readAfterSerialization",
                "modifyBeforeRetryLoop",
                "readBeforeAttempt",
                "selectAuthScheme",
                "applyEndpoint",
                "modifyBeforeSigning",
                "readBeforeSigning",
                "applySigner",
                "readAfterSigning",
                "modifyBeforeTransmit",
                "readBeforeTransmit",
                "executeRequest",
                "readAfterTransmit",
                "modifyBeforeDeserialization",
                "modifyBeforeAttemptCompletion",
                "readAfterAttempt",
                "errorInfo",
                "modifyBeforeCompletion",
                "readAfterExecution",
            ]
        )
    }

    func test_stepErrorHandlingReadBeforeDeserialization() async {
        let readBeforeDeserializationTrace = Trace()
        let readBeforeDeserialization = await asyncResult {
            let b = self.traceOrchestrator(trace: readBeforeDeserializationTrace)
            b.interceptors.addReadBeforeDeserialization({ _ in throw TestError(value: "1") })
            b.interceptors.addReadBeforeDeserialization({ _ in throw TestError(value: "2") })
            return try await b.build().execute(input: TestInput(foo: ""))
        }

        XCTAssertEqual(readBeforeDeserialization, .failure(TestError(value: "2")))
        XCTAssertEqual(
            readBeforeDeserializationTrace.trace,
            [
                "readBeforeExecution",
                "modifyBeforeSerialization",
                "readBeforeSerialization",
                "serialize",
                "readAfterSerialization",
                "modifyBeforeRetryLoop",
                "readBeforeAttempt",
                "selectAuthScheme",
                "applyEndpoint",
                "modifyBeforeSigning",
                "readBeforeSigning",
                "applySigner",
                "readAfterSigning",
                "modifyBeforeTransmit",
                "readBeforeTransmit",
                "executeRequest",
                "readAfterTransmit",
                "modifyBeforeDeserialization",
                "readBeforeDeserialization",
                "modifyBeforeAttemptCompletion",
                "readAfterAttempt",
                "errorInfo",
                "modifyBeforeCompletion",
                "readAfterExecution",
            ]
        )
    }

    func test_stepErrorHandlingDeserialize() async {
        let trace = Trace()
        let result = await asyncResult {
            return try await self.traceOrchestrator(trace: trace)
                .deserialize { _, _ in
                    trace.append("deserialize")
                    throw TestError(value: "1")
                }
                .build()
                .execute(input: TestInput(foo: ""))
        }

        XCTAssertEqual(result, .failure(TestError(value: "1")))
        XCTAssertEqual(
            trace.trace,
            [
                "readBeforeExecution",
                "modifyBeforeSerialization",
                "readBeforeSerialization",
                "serialize",
                "readAfterSerialization",
                "modifyBeforeRetryLoop",
                "readBeforeAttempt",
                "selectAuthScheme",
                "applyEndpoint",
                "modifyBeforeSigning",
                "readBeforeSigning",
                "applySigner",
                "readAfterSigning",
                "modifyBeforeTransmit",
                "readBeforeTransmit",
                "executeRequest",
                "readAfterTransmit",
                "modifyBeforeDeserialization",
                "readBeforeDeserialization",
                "deserialize",
                "modifyBeforeAttemptCompletion",
                "readAfterAttempt",
                "errorInfo",
                "modifyBeforeCompletion",
                "readAfterExecution",
            ]
        )
    }

    func test_stepErrorHandlingReadAfterDeserialization() async {
        let readAfterDeserializationTrace = Trace()
        let readAfterDeserialization = await asyncResult {
            let b = self.traceOrchestrator(trace: readAfterDeserializationTrace)
            b.interceptors.addReadAfterDeserialization({ _ in throw TestError(value: "1") })
            b.interceptors.addReadAfterDeserialization({ _ in throw TestError(value: "2") })
            return try await b.build().execute(input: TestInput(foo: ""))
        }

        XCTAssertEqual(readAfterDeserialization, .failure(TestError(value: "2")))
        XCTAssertEqual(
            readAfterDeserializationTrace.trace,
            [
                "readBeforeExecution",
                "modifyBeforeSerialization",
                "readBeforeSerialization",
                "serialize",
                "readAfterSerialization",
                "modifyBeforeRetryLoop",
                "readBeforeAttempt",
                "selectAuthScheme",
                "applyEndpoint",
                "modifyBeforeSigning",
                "readBeforeSigning",
                "applySigner",
                "readAfterSigning",
                "modifyBeforeTransmit",
                "readBeforeTransmit",
                "executeRequest",
                "readAfterTransmit",
                "modifyBeforeDeserialization",
                "readBeforeDeserialization",
                "deserialize",
                "readAfterDeserialization",
                "modifyBeforeAttemptCompletion",
                "readAfterAttempt",
                "errorInfo",
                "modifyBeforeCompletion",
                "readAfterExecution",
            ]
        )
    }

    func test_stepErrorHandlingModifyBeforeAttemptCompletion() async {
        let modifyBeforeAttemptCompletionTrace = Trace()
        let modifyBeforeAttemptCompletion = await asyncResult {
            let b = self.traceOrchestrator(trace: modifyBeforeAttemptCompletionTrace)
            b.interceptors.addModifyBeforeAttemptCompletion({ _ in throw TestError(value: "1") })
            b.interceptors.addModifyBeforeAttemptCompletion({ _ in throw TestError(value: "2") })
            return try await b.build().execute(input: TestInput(foo: ""))
        }

        XCTAssertEqual(modifyBeforeAttemptCompletion, .failure(TestError(value: "2")))
        XCTAssertEqual(
            modifyBeforeAttemptCompletionTrace.trace,
            [
                "readBeforeExecution",
                "modifyBeforeSerialization",
                "readBeforeSerialization",
                "serialize",
                "readAfterSerialization",
                "modifyBeforeRetryLoop",
                "readBeforeAttempt",
                "selectAuthScheme",
                "applyEndpoint",
                "modifyBeforeSigning",
                "readBeforeSigning",
                "applySigner",
                "readAfterSigning",
                "modifyBeforeTransmit",
                "readBeforeTransmit",
                "executeRequest",
                "readAfterTransmit",
                "modifyBeforeDeserialization",
                "readBeforeDeserialization",
                "deserialize",
                "readAfterDeserialization",
                "modifyBeforeAttemptCompletion",
                "readAfterAttempt",
                "errorInfo",
                "modifyBeforeCompletion",
                "readAfterExecution",
            ]
        )
    }

    func test_stepErrorHandlingReadAfterAttempt() async {
        let readAfterAttemptTrace = Trace()
        let readAfterAttempt = await asyncResult {
            let b = self.traceOrchestrator(trace: readAfterAttemptTrace)
            b.interceptors.addReadAfterAttempt({ _ in throw TestError(value: "1") })
            b.interceptors.addReadAfterAttempt({ _ in throw TestError(value: "2") })
            return try await b.build().execute(input: TestInput(foo: ""))
        }

        XCTAssertEqual(readAfterAttempt, .failure(TestError(value: "2")))
        XCTAssertEqual(
            readAfterAttemptTrace.trace,
            [
                "readBeforeExecution",
                "modifyBeforeSerialization",
                "readBeforeSerialization",
                "serialize",
                "readAfterSerialization",
                "modifyBeforeRetryLoop",
                "readBeforeAttempt",
                "selectAuthScheme",
                "applyEndpoint",
                "modifyBeforeSigning",
                "readBeforeSigning",
                "applySigner",
                "readAfterSigning",
                "modifyBeforeTransmit",
                "readBeforeTransmit",
                "executeRequest",
                "readAfterTransmit",
                "modifyBeforeDeserialization",
                "readBeforeDeserialization",
                "deserialize",
                "readAfterDeserialization",
                "modifyBeforeAttemptCompletion",
                "readAfterAttempt",
                "errorInfo",
                "modifyBeforeCompletion",
                "readAfterExecution",
            ]
        )
    }

    func test_stepErrorHandlingModifyBeforeCompletion() async {
        let modifyBeforeCompletionTrace = Trace()
        let modifyBeforeCompletion = await asyncResult {
            let b = self.traceOrchestrator(trace: modifyBeforeCompletionTrace)
            b.interceptors.addModifyBeforeCompletion({ _ in throw TestError(value: "1") })
            b.interceptors.addModifyBeforeCompletion({ _ in throw TestError(value: "2") })
            return try await b.build().execute(input: TestInput(foo: ""))
        }

        XCTAssertEqual(modifyBeforeCompletion, .failure(TestError(value: "2")))
        XCTAssertEqual(
            modifyBeforeCompletionTrace.trace,
            [
                "readBeforeExecution",
                "modifyBeforeSerialization",
                "readBeforeSerialization",
                "serialize",
                "readAfterSerialization",
                "modifyBeforeRetryLoop",
                "readBeforeAttempt",
                "selectAuthScheme",
                "applyEndpoint",
                "modifyBeforeSigning",
                "readBeforeSigning",
                "applySigner",
                "readAfterSigning",
                "modifyBeforeTransmit",
                "readBeforeTransmit",
                "executeRequest",
                "readAfterTransmit",
                "modifyBeforeDeserialization",
                "readBeforeDeserialization",
                "deserialize",
                "readAfterDeserialization",
                "modifyBeforeAttemptCompletion",
                "readAfterAttempt",
                "modifyBeforeCompletion",
                "readAfterExecution",
            ]
        )
    }

    func test_stepErrorHandlingReadAfterExecution() async {
        let readAfterExecutionTrace = Trace()
        let readAfterExecution = await asyncResult {
            let b = self.traceOrchestrator(trace: readAfterExecutionTrace)
            b.interceptors.addReadAfterExecution({ _ in throw TestError(value: "1") })
            b.interceptors.addReadAfterExecution({ _ in throw TestError(value: "2") })
            return try await b.build().execute(input: TestInput(foo: ""))
        }

        XCTAssertEqual(readAfterExecution, .failure(TestError(value: "2")))
        XCTAssertEqual(
            readAfterExecutionTrace.trace,
            [
                "readBeforeExecution",
                "modifyBeforeSerialization",
                "readBeforeSerialization",
                "serialize",
                "readAfterSerialization",
                "modifyBeforeRetryLoop",
                "readBeforeAttempt",
                "selectAuthScheme",
                "applyEndpoint",
                "modifyBeforeSigning",
                "readBeforeSigning",
                "applySigner",
                "readAfterSigning",
                "modifyBeforeTransmit",
                "readBeforeTransmit",
                "executeRequest",
                "readAfterTransmit",
                "modifyBeforeDeserialization",
                "readBeforeDeserialization",
                "deserialize",
                "readAfterDeserialization",
                "modifyBeforeAttemptCompletion",
                "readAfterAttempt",
                "modifyBeforeCompletion",
                "readAfterExecution",
            ]
        )
    }

    func test_throwsLastInterceptorErrorAndLogsRest() async {
        let logger = TraceLogger()
        let trace = Trace()
        let result = await asyncResult {
            let b = self.traceOrchestrator(trace: trace)
            b.attributes?.set(key: AttributeKeys.logger, value: logger)
            b.interceptors.addReadBeforeExecution({ _ in throw TestError(value: "firstError") })
            b.interceptors.addReadBeforeExecution({ _ in throw TestError(value: "secondError") })
            return try await b.build().execute(input: TestInput(foo: ""))
        }

        XCTAssertEqual(result, .failure(TestError(value: "secondError")))
        XCTAssertEqual(
            trace.trace,
            [
                "readBeforeExecution",
                "modifyBeforeCompletion",
                "readAfterExecution",
            ]
        )

        XCTAssertEqual(logger.trace.trace.count, 1)
        let firstError = logger.trace.trace[0]
        XCTAssert(firstError.contains("firstError"), "Expected first error to contain `firstError` but was: `\(firstError)`")

    }

    private func asyncResult(_ fn: @escaping () async throws -> TestOutput) async -> Result<TestOutput, TestError> {
        do {
            let output = try await fn()
            return .success(output)
        } catch let e {
            if let e = e as? TestError {
                return .failure(e)
            } else {
                return .failure(TestError(value: e.localizedDescription))
            }
        }
    }
}
