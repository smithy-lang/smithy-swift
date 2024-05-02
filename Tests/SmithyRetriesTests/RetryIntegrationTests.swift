//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
import SmithyRetriesAPI
@testable import SmithyRetries
@testable import ClientRuntime

// This test class reproduces the "Standard Mode" test cases defined in "Retry Behavior 2.0"
final class RetryIntegrationTests: XCTestCase {
    private let partitionIDKey = AttributeKey<String>(name: "PartitionID")
    private let partitionID = "partition"

    private var context: HttpContext!
    private var next: TestOutputHandler!
    private var subject: RetryMiddleware<DefaultRetryStrategy, DefaultRetryErrorInfoProvider, TestOutputResponse>!
    private var quota: RetryQuota { get async { await subject.strategy.quotaRepository.quota(partitionID: partitionID) } }

    private func setUp(availableCapacity: Int, maxCapacity: Int, maxRetriesBase: Int, maxBackoff: TimeInterval) async {
        // Setup the HTTP context, used by the retry middleware
        context = HttpContext(attributes: Attributes())
        context.attributes.set(key: partitionIDKey, value: partitionID)
        context.attributes.set(key: AttributeKeys.socketTimeout, value: 60.0)
        context.attributes.set(key: AttributeKeys.estimatedSkew, value: 30.0)

        // Create the test output handler, which is the "next" middleware called by the retry middleware
        next = TestOutputHandler()

        // Create a backoff strategy with custom max backoff and no randomization
        let backoffStrategyOptions = ExponentialBackoffStrategyOptions(jitterType: .default, backoffScaleValue: 0.025, maxBackoff: maxBackoff)
        var backoffStrategy = ExponentialBackoffStrategy(options: backoffStrategyOptions)
        backoffStrategy.random = { 1.0 }

        // Create a retry strategy with custom backoff strategy & custom max retries & custom capacity
        let retryStrategyOptions = RetryStrategyOptions(backoffStrategy: backoffStrategy, maxRetriesBase: maxRetriesBase, availableCapacity: availableCapacity, maxCapacity: maxCapacity)
        subject = RetryMiddleware<DefaultRetryStrategy, DefaultRetryErrorInfoProvider, TestOutputResponse>(options: retryStrategyOptions)

        // Replace the retry strategy's sleeper with a mock, to allow tests to run without delay and for us to
        // check the delay time
        // Treat nil and 0.0 time the same (change 0.0 to nil)
        subject.strategy.sleeper = { self.next.actualDelay = ($0 != 0.0) ? $0 : nil }

        // Set the quota on the test output handler so it can verify state during tests
        next.quota = await quota
    }

    // MARK: - Standard mode

    func test_case1() async throws {
        await setUp(availableCapacity: 500, maxCapacity: 500, maxRetriesBase: 2, maxBackoff: 20.0)
        next.testSteps = [
            TestStep(response: .httpError(500), expectedOutcome: .retryRequest, retryQuota: 495, delay: 1.0),
            TestStep(response: .httpError(500), expectedOutcome: .retryRequest, retryQuota: 490, delay: 2.0),
            TestStep(response: .success, expectedOutcome: .success, retryQuota: 495, delay: nil)
        ]
        try await runTest()
    }

    func test_case2() async throws {
        await setUp(availableCapacity: 500, maxCapacity: 500, maxRetriesBase: 2, maxBackoff: 20.0)
        next.testSteps = [
            TestStep(response: .httpError(502), expectedOutcome: .retryRequest, retryQuota: 495, delay: 1.0),
            TestStep(response: .httpError(502), expectedOutcome: .retryRequest, retryQuota: 490, delay: 2.0),
            TestStep(response: .httpError(502), expectedOutcome: .maxAttemptsExceeded, retryQuota: 490, delay: nil)
        ]
        try await runTest()
    }

    func test_case3() async throws {
        await setUp(availableCapacity: 5, maxCapacity: 500, maxRetriesBase: 2, maxBackoff: 20.0)
        next.testSteps = [
            TestStep(response: .httpError(500), expectedOutcome: .retryRequest, retryQuota: 0, delay: 1.0),
            TestStep(response: .httpError(502), expectedOutcome: .retryQuotaExceeded, retryQuota: 0, delay: nil)
        ]
        try await runTest()
    }

    func test_case4() async throws {
        await setUp(availableCapacity: 0, maxCapacity: 500, maxRetriesBase: 2, maxBackoff: 20.0)
        next.testSteps = [
            TestStep(response: .httpError(500), expectedOutcome: .retryQuotaExceeded, retryQuota: 0, delay: nil),
        ]
        try await runTest()
    }

    func test_case5() async throws {
        await setUp(availableCapacity: 500, maxCapacity: 500, maxRetriesBase: 4, maxBackoff: 20.0)
        next.testSteps = [
            TestStep(response: .httpError(500), expectedOutcome: .retryRequest, retryQuota: 495, delay: 1.0),
            TestStep(response: .httpError(500), expectedOutcome: .retryRequest, retryQuota: 490, delay: 2.0),
            TestStep(response: .httpError(500), expectedOutcome: .retryRequest, retryQuota: 485, delay: 4.0),
            TestStep(response: .httpError(500), expectedOutcome: .retryRequest, retryQuota: 480, delay: 8.0),
            TestStep(response: .httpError(500), expectedOutcome: .maxAttemptsExceeded, retryQuota: 480, delay: nil)
        ]
        try await runTest()
    }

    func test_case6() async throws {
        await setUp(availableCapacity: 500, maxCapacity: 500, maxRetriesBase: 4, maxBackoff: 3.0)
        next.testSteps = [
            TestStep(response: .httpError(500), expectedOutcome: .retryRequest, retryQuota: 495, delay: 1.0),
            TestStep(response: .httpError(500), expectedOutcome: .retryRequest, retryQuota: 490, delay: 2.0),
            TestStep(response: .httpError(500), expectedOutcome: .retryRequest, retryQuota: 485, delay: 3.0),
            TestStep(response: .httpError(500), expectedOutcome: .retryRequest, retryQuota: 480, delay: 3.0),
            TestStep(response: .httpError(500), expectedOutcome: .maxAttemptsExceeded, retryQuota: 480, delay: nil)
        ]
        try await runTest()
    }

    private func runTest() async throws {
        do {
            _ = try await subject.handle(context: context, input: SdkHttpRequestBuilder(), next: next)
        } catch {
            next.finalError = error
        }
        try await next.verifyResult()
    }

    // Test getEstimatedSkew utility method.
    func test_getEstimatedSkew() {
        let responseDateString = "Mon, 15 Jul 2024 01:24:12 GMT"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss z"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
        let responseDate: Date = dateFormatter.date(from: responseDateString)!

        let responseDateStringPlusTen = "Mon, 15 Jul 2024 01:24:22 GMT"
        let estimatedSkew = getEstimatedSkew(now: responseDate, responseDateString: responseDateStringPlusTen)

        XCTAssertEqual(estimatedSkew, 10.0)
    }

    // Test getTTLutility method.
    func test_getTTL() {
        let nowDateString = "Mon, 15 Jul 2024 01:24:12 GMT"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss z"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
        let nowDate: Date = dateFormatter.date(from: nowDateString)!

        // The two timeintervals below add up to 34  minutes 59 seconds, rounding to closest second.
        let estimatedSkew = 2039.34
        let socketTimeout = 60.0

        // Verify calculated TTL is nowDate + (34 minutes and 59 seconds).
        let ttl = getTTL(now: nowDate, estimatedSkew: estimatedSkew, socketTimeout: socketTimeout)
        XCTAssertEqual(ttl, "20240715T015911Z")
    }
}

private struct TestStep {

    enum Response: Equatable {
        case success
        case httpError(Int)
    }

    enum Outcome: Equatable {
        case retryRequest
        case success
        case maxAttemptsExceeded
        case retryQuotaExceeded
    }

    let response: Response
    let expectedOutcome: Outcome
    let retryQuota: Int
    let delay: TimeInterval?
    let file: StaticString
    let line: UInt

    init(response: Response, expectedOutcome: Outcome, retryQuota: Int, delay: TimeInterval?, file: StaticString = #file, line: UInt = #line) {
        self.response = response
        self.expectedOutcome = expectedOutcome
        self.retryQuota = retryQuota
        self.delay = delay
        self.file = file
        self.line = line
    }
}

private struct TestInput {}

private struct TestOutputResponse: HttpResponseBinding {
    init() {}
    init(httpResponse: ClientRuntime.HttpResponse, decoder: ClientRuntime.ResponseDecoder?) async throws {}
}

private enum TestOutputError: HttpResponseErrorBinding {
    static func makeError(httpResponse: ClientRuntime.HttpResponse, decoder: ClientRuntime.ResponseDecoder?) async throws -> Error {
        RetryIntegrationTestError.dontCallThisMethod  // is never called
    }
}

private class TestOutputHandler: Handler {

    typealias Input = SdkHttpRequestBuilder
    typealias Output = OperationOutput<TestOutputResponse>
    typealias Context = HttpContext

    var index = 0
    fileprivate var testSteps = [TestStep]()
    private var latestTestStep: TestStep?
    var quota: RetryQuota!
    var actualDelay: TimeInterval?
    var finalError: Error?
    var invocationID = ""
    var prevAttemptNum = 0

    func handle(context: ClientRuntime.HttpContext, input: SdkHttpRequestBuilder) async throws -> OperationOutput<TestOutputResponse> {
        if index == testSteps.count { throw RetryIntegrationTestError.maxAttemptsExceeded }

        // Verify the results of the previous test step, if there was one.
        try await verifyResult(atEnd: false)
        // Verify the input's retry information headers.
        try await verifyInput(input: input)

        // Get the latest test step, then advance the index.
        let testStep = testSteps[index]
        latestTestStep = testStep
        index += 1

        // Return either a successful response or a HTTP error, depending on the directions in the test step.
        switch testStep.response {
        case .success:
            return Output(httpResponse: HttpResponse(), output: TestOutputResponse())
        case .httpError(let statusCode):
            throw TestHTTPError(statusCode: statusCode)
        }
    }

    func verifyResult(atEnd: Bool = true) async throws {
        guard let testStep = latestTestStep else { return }

        // Test available capacity
        let availableCapacity = await quota.availableCapacity
        XCTAssertEqual(testStep.retryQuota, availableCapacity)

        // Test delay
        XCTAssertEqual(testStep.delay, actualDelay, file: testStep.file, line: testStep.line)
        actualDelay = nil

        // When called after all test steps have been performed, this
        // logic will verify that the last test step had the expected result.
        guard atEnd else { return }
        switch testStep.expectedOutcome {
        case .success:
            if let error = finalError { XCTFail("Unexpected error: \(error)", file: testStep.file, line: testStep.line) }
        case .retryQuotaExceeded, .maxAttemptsExceeded:
            if !(finalError is TestHTTPError) { XCTFail("Test did not end on service error", file: testStep.file, line: testStep.line) }
        case .retryRequest:
            XCTFail("Test should not end on retry", file: testStep.file, line: testStep.line)
        }
    }

    func verifyInput(input: SdkHttpRequestBuilder) async throws {
        // Get invocation ID of the request off of amz-sdk-invocation-id header.
        let invocationID = try XCTUnwrap(input.headers.value(for: "amz-sdk-invocation-id"))
        // If this is the first request, save the retrieved ID.
        if (self.invocationID.isEmpty) { self.invocationID = invocationID }

        // Retrieved IDs from all requests under a same call must be the same.
        XCTAssertEqual(self.invocationID, invocationID)

        // Get retry information off of amz-sdk-request header.
        let amzSdkRequestHeaderValue = try XCTUnwrap(input.headers.value(for: "amz-sdk-request"))
        // Extract request pair values from amz-sdk-request header value.
        let requestPairs = amzSdkRequestHeaderValue.components(separatedBy: "; ")
        var ttl: String = ""
        let attemptNum: Int = try XCTUnwrap(
            Int(
                try XCTUnwrap(requestPairs.first { $0.hasPrefix("attempt=") })
                    .components(separatedBy: "=")[1]
            )
        )
        _ = try XCTUnwrap(
            Int(
                try XCTUnwrap(requestPairs.first { $0.hasPrefix("max=") })
                    .components(separatedBy: "=")[1]
            )
        )
        // For attempts 2+, TTL must be present.
        if (attemptNum > 1) {
            ttl = try XCTUnwrap(requestPairs.first { $0.hasPrefix("ttl") }).components(separatedBy: "=")[1]
            // Check that TTL date is in strftime format.
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
            XCTAssertNotNil(dateFormatter.date(from: ttl))
        }

        // Verify attempt number was incremented by 1 from previous request.
        XCTAssertEqual(attemptNum, (self.prevAttemptNum + 1))
        self.prevAttemptNum = attemptNum
    }
}

// Thrown during a test to simulate a server response with a given HTTP status code.
private struct TestHTTPError: HTTPError, Error {
    var httpResponse: ClientRuntime.HttpResponse

    init(statusCode: Int) {
        guard let statusCodeValue = HttpStatusCode(rawValue: statusCode) else { fatalError("Unrecognized HTTP code") }
        self.httpResponse = HttpResponse(statusCode: statusCodeValue)
    }
}

// These errors are thrown when a test fails.
private enum RetryIntegrationTestError: Error {
    case dontCallThisMethod
    case noRemainingTestSteps
    case maxAttemptsExceeded
    case unexpectedSuccess
    case unexpectedFailure
}
