//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
@testable import ClientRuntime

// This test class reproduces the "Standard Mode" test cases defined in "Retry Behavior 2.0"
final class RetryIntegrationTests: XCTestCase {
    private let partitionIDKey = AttributeKey<String>(name: "PartitionID")
    private let partitionID = "partition"

    private var context: HttpContext!
    private var next: TestOutputHandler!
    private var mockSleeper: MockSleeper!
    private var subject: RetryMiddleware<DefaultRetryStrategy, DefaultRetryErrorInfoProvider, TestOutputResponse, TestOutputError>!
    private var quota: RetryQuota { get async { await subject.strategy.quotaRepository.quota(partitionID: partitionID) } }

    private func setUp(availableCapacity: Int, maxCapacity: Int, maxRetriesBase: Int, maxBackoff: TimeInterval) async {
        // Setup the HTTP context, used by the retry middleware
        context = HttpContext(attributes: Attributes())
        context.attributes.set(key: partitionIDKey, value: partitionID)

        // Create the test output handler, which is the "next" middleware called by the retry middleware
        next = TestOutputHandler()

        // Create a backoff strategy with custom max backoff and no randomization
        let backoffStrategyOptions = ExponentialBackoffStrategyOptions(jitterType: .default, backoffScaleValue: 0.025, maxBackoff: maxBackoff)
        var backoffStrategy = ExponentialBackoffStrategy(options: backoffStrategyOptions)
        backoffStrategy.random = { 1.0 }

        // Create a retry strategy with custom backoff strategy & custom max retries & custom capacity
        let retryStrategyOptions = RetryStrategyOptions(backoffStrategy: backoffStrategy, maxRetriesBase: maxRetriesBase, availableCapacity: availableCapacity, maxCapacity: maxCapacity)
        subject = RetryMiddleware<DefaultRetryStrategy, DefaultRetryErrorInfoProvider, TestOutputResponse, TestOutputError>(options: retryStrategyOptions)

        // Replace the retry strategy's sleeper with a mock, to allow tests to run without delay and for us to
        // check the delay time
        mockSleeper = MockSleeper()
        subject.strategy.sleeper = mockSleeper

        // Set the quota & sleeper on the test output handler so it can verify state during tests
        next.quota = await quota
        next.sleeper = mockSleeper
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
}

struct TestStep {

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
}

struct TestInput {}

struct TestOutputResponse: HttpResponseBinding {
    init() {}
    init(httpResponse: ClientRuntime.HttpResponse, decoder: ClientRuntime.ResponseDecoder?) async throws {}
}

enum TestOutputError: HttpResponseErrorBinding {
    static func makeError(httpResponse: ClientRuntime.HttpResponse, decoder: ClientRuntime.ResponseDecoder?) async throws -> Error {
        RetryIntegrationTestError.dontCallThisMethod  // is never called
    }
}

class TestOutputHandler: Handler {

    typealias Input = SdkHttpRequestBuilder
    typealias Output = OperationOutput<TestOutputResponse>
    typealias Context = HttpContext

    var index = 0
    var testSteps = [TestStep]()
    var latestTestStep: TestStep?
    var quota: RetryQuota!
    var sleeper: MockSleeper!
    var finalError: Error?

    func handle(context: ClientRuntime.HttpContext, input: SdkHttpRequestBuilder) async throws -> OperationOutput<TestOutputResponse> {
        if index == testSteps.count { throw MaxAttemptsExceeded() }

        // Verify the results of the previous test step, if there was one.
        try await verifyResult(atEnd: false)

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
        let actualDelay = sleeper.sleepTime.map(TimeInterval.init)?.map { $0 / 1_000_000_000.0 }
        XCTAssertEqual(testStep.delay, actualDelay)
        sleeper.sleepTime = nil

        guard atEnd else { return }
        switch testStep.expectedOutcome {
        case .success:
            if let error = finalError { XCTFail("Unexpected error: \(error)") }
        case .retryQuotaExceeded, .maxAttemptsExceeded:
            if !(finalError is TestHTTPError) { XCTFail("Test did not end on service error") }
        case .retryRequest:
            XCTFail("Test should not end on retry")
        }
    }
}

struct TestHTTPError: HTTPError, Error {
    var httpResponse: ClientRuntime.HttpResponse

    init(statusCode: Int) {
        guard let statusCodeValue = HttpStatusCode(rawValue: statusCode) else { fatalError("Unrecognized HTTP code") }
        self.httpResponse = HttpResponse(statusCode: statusCodeValue)
    }
}

enum RetryIntegrationTestError: Error {
    case dontCallThisMethod
    case noRemainingTestSteps
    case maxAttemptsExceeded
    case unexpectedSuccess
    case unexpectedFailure
}

struct MaxAttemptsExceeded: ModeledError, Error {
    static var typeName: String { "MaxAttemptsExceeded" }
    static var fault: ClientRuntime.ErrorFault { .client }
    static var isRetryable: Bool { false }
    static var isThrottling: Bool { false }
}
