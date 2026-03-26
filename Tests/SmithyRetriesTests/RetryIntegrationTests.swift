//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Smithy
import SmithyHTTPAPI
import SmithyHTTPAuthAPI
import SmithyReadWrite
import SmithyXML
import XCTest
import SmithyRetriesAPI
import SmithyTestUtil
@testable import SmithyRetries
@testable import ClientRuntime

// This test class reproduces the "Standard Mode" test cases derived from Retries SEP 2.1
final class RetryIntegrationTests: XCTestCase {
    private let partitionID = "partition"

    private var context: Context!
    private var next: TestOutputHandler!
    private var subject: DefaultRetryStrategy!

    private var builder: OrchestratorBuilder<TestInput, TestOutputResponse, HTTPRequest, HTTPResponse>!
    private var quota: RetryQuota { get async { await subject.quotaRepository.quota(partitionID: partitionID) } }

    private func setUp(availableCapacity: Int, maxCapacity: Int, maxRetriesBase: Int, maxBackoff: TimeInterval) async {
        context = Context(attributes: Attributes())
        context.partitionID = partitionID
        context.socketTimeout = 60.0
        context.estimatedSkew = 30.0

        next = TestOutputHandler()

        let backoffStrategyOptions = ExponentialBackoffStrategyOptions(jitterType: .default, backoffScaleValue: 0.025, maxBackoff: maxBackoff)
        var backoffStrategy = ExponentialBackoffStrategy(options: backoffStrategyOptions)
        backoffStrategy.random = { 1.0 }

        let retryStrategyOptions = RetryStrategyOptions(backoffStrategy: backoffStrategy, maxRetriesBase: maxRetriesBase, availableCapacity: availableCapacity, maxCapacity: maxCapacity)
        subject = DefaultRetryStrategy(options: retryStrategyOptions)
        subject.sleeper = { self.next.actualDelay = ($0 != 0.0) ? $0 : nil }

        builder = TestOrchestrator.httpBuilder()
            .attributes(context)
            .retryErrorInfoProvider(DefaultRetryErrorInfoProvider.errorInfo(for:))
            .retryStrategy(subject)
            .deserialize({ response, _ in
                if response.statusCode == .ok {
                    return TestOutputResponse()
                } else {
                    throw TestHTTPError(statusCode: response.statusCode)
                }
            })
            .executeRequest(next)

        next.quota = await quota
    }

    // MARK: - SEP 2.1 Standard mode tests
    // Non-throttling errors use RETRY_COST=14, backoff multiplier x=0.05
    // With random=1.0: delays are 0.05, 0.1, 0.2, 0.4, ...

    func test_case1() async throws {
        await setUp(availableCapacity: 500, maxCapacity: 500, maxRetriesBase: 2, maxBackoff: 20.0)
        next.testSteps = [
            TestStep(response: .httpError(500), expectedOutcome: .retryRequest, retryQuota: 486, delay: 0.05),
            TestStep(response: .httpError(500), expectedOutcome: .retryRequest, retryQuota: 472, delay: 0.1),
            TestStep(response: .success, expectedOutcome: .success, retryQuota: 486, delay: nil)
        ]
        try await runTest()
    }

    func test_case2() async throws {
        await setUp(availableCapacity: 500, maxCapacity: 500, maxRetriesBase: 2, maxBackoff: 20.0)
        next.testSteps = [
            TestStep(response: .httpError(502), expectedOutcome: .retryRequest, retryQuota: 486, delay: 0.05),
            TestStep(response: .httpError(502), expectedOutcome: .retryRequest, retryQuota: 472, delay: 0.1),
            TestStep(response: .httpError(502), expectedOutcome: .maxAttemptsExceeded, retryQuota: 472, delay: nil)
        ]
        try await runTest()
    }

    func test_case3() async throws {
        // SEP 2.1: RETRY_COST=14, so need at least 14 tokens for first retry
        await setUp(availableCapacity: 14, maxCapacity: 500, maxRetriesBase: 2, maxBackoff: 20.0)
        next.testSteps = [
            TestStep(response: .httpError(500), expectedOutcome: .retryRequest, retryQuota: 0, delay: 0.05),
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
            TestStep(response: .httpError(500), expectedOutcome: .retryRequest, retryQuota: 486, delay: 0.05),
            TestStep(response: .httpError(500), expectedOutcome: .retryRequest, retryQuota: 472, delay: 0.1),
            TestStep(response: .httpError(500), expectedOutcome: .retryRequest, retryQuota: 458, delay: 0.2),
            TestStep(response: .httpError(500), expectedOutcome: .retryRequest, retryQuota: 444, delay: 0.4),
            TestStep(response: .httpError(500), expectedOutcome: .maxAttemptsExceeded, retryQuota: 444, delay: nil)
        ]
        try await runTest()
    }

    func test_case6() async throws {
        // maxBackoff=3.0 caps the delay
        await setUp(availableCapacity: 500, maxCapacity: 500, maxRetriesBase: 4, maxBackoff: 3.0)
        next.testSteps = [
            TestStep(response: .httpError(500), expectedOutcome: .retryRequest, retryQuota: 486, delay: 0.05),
            TestStep(response: .httpError(500), expectedOutcome: .retryRequest, retryQuota: 472, delay: 0.1),
            TestStep(response: .httpError(500), expectedOutcome: .retryRequest, retryQuota: 458, delay: 0.2),
            TestStep(response: .httpError(500), expectedOutcome: .retryRequest, retryQuota: 444, delay: 0.4),
            TestStep(response: .httpError(500), expectedOutcome: .maxAttemptsExceeded, retryQuota: 444, delay: nil)
        ]
        try await runTest()
    }

    private func runTest() async throws {
        do {
            _ = try await builder.build().execute(input: TestInput())
        } catch {
            next.finalError = error
        }
        try await next.verifyResult()
    }

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

private struct TestOutputResponse {
    init() {}
}

private enum TestOutputError {
    static func httpError(from httpResponse: HTTPResponse) async throws -> Error  {
        RetryIntegrationTestError.dontCallThisMethod
    }
}

private class TestOutputHandler: ExecuteRequest {
    typealias RequestType = HTTPRequest
    typealias ResponseType = HTTPResponse

    var index = 0
    fileprivate var testSteps = [TestStep]()
    private var latestTestStep: TestStep?
    var quota: RetryQuota!
    var actualDelay: TimeInterval?
    var finalError: Error?
    var invocationID = ""
    var prevAttemptNum = 0

    func execute(request: SmithyHTTPAPI.HTTPRequest, attributes: Smithy.Context) async throws -> SmithyHTTPAPI.HTTPResponse {
        if index == testSteps.count { throw RetryIntegrationTestError.maxAttemptsExceeded }

        try await verifyResult(atEnd: false)

        let testStep = testSteps[index]
        latestTestStep = testStep
        index += 1

        switch testStep.response {
        case .success:
            return HTTPResponse(statusCode: .ok)
        case .httpError(let statusCode):
            let httpStatusCode = HTTPStatusCode(rawValue: statusCode)!
            return HTTPResponse(statusCode: httpStatusCode)
        }
    }

    func verifyResult(atEnd: Bool = true) async throws {
        guard let testStep = latestTestStep else {
            if atEnd {
                XCTFail("No test steps were run! Encountered error: \(String(describing: finalError!))")
            }
            return
        }

        let availableCapacity = await quota.availableCapacity
        XCTAssertEqual(testStep.retryQuota, availableCapacity)

        XCTAssertEqual(testStep.delay, actualDelay, file: testStep.file, line: testStep.line)
        actualDelay = nil

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
}

private struct TestHTTPError: HTTPError, Error {
    var httpResponse: HTTPResponse

    init(statusCode: HTTPStatusCode) {
        self.httpResponse = HTTPResponse(statusCode: statusCode)
    }
}

private enum RetryIntegrationTestError: Error {
    case dontCallThisMethod
    case noRemainingTestSteps
    case maxAttemptsExceeded
    case unexpectedSuccess
    case unexpectedFailure
}
