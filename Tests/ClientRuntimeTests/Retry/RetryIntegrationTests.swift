//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
@testable import ClientRuntime

class RetryIntegrationTests: XCTestCase {
    let partitionIDKey = AttributeKey<String>(name: "PartitionID")
    let partitionID = "partition"

    var context: HttpContext!
    var next: TestOutputHandler!
    var mockSleeper: MockSleeper!
    var subject: RetryMiddleware<DefaultRetryStrategy, DefaultRetryErrorInfoProvider, TestOutputResponse, TestOutputError>!
    var quota: RetryQuota { get async { await subject.strategy.quotaRepository.quota(partitionID: partitionID) } }

    func setUp(availableCapacity: Int, maxCapacity: Int, maxRetriesBase: Int) async {
        context = HttpContext(attributes: Attributes())
        context.attributes.set(key: partitionIDKey, value: partitionID)
        next = TestOutputHandler()
        var backoffStrategy = ExponentialBackoffStrategy(options: .default)
        backoffStrategy.random = { 1.0 }
        let retryStrategyOptions = RetryStrategyOptions(backoffStrategy: backoffStrategy, maxRetriesBase: maxRetriesBase, availableCapacity: availableCapacity, maxCapacity: maxCapacity)
        subject = RetryMiddleware<DefaultRetryStrategy, DefaultRetryErrorInfoProvider, TestOutputResponse, TestOutputError>(options: retryStrategyOptions)
        mockSleeper = MockSleeper()
        subject.strategy.sleeper = mockSleeper
        next.quota = await quota
        next.sleeper = mockSleeper
    }

    func test_case1() async throws {
        await setUp(availableCapacity: 500, maxCapacity: 500, maxRetriesBase: 2)
        next.testSteps = [
            TestStep(response: .httpError(500), expectedOutcome: .retryRequest, retryQuota: 495, delay: 1.0),
            TestStep(response: .httpError(500), expectedOutcome: .retryRequest, retryQuota: 490, delay: 2.0),
            TestStep(response: .success, expectedOutcome: .success, retryQuota: 495, delay: nil)
        ]
        do {
            _ = try await subject.handle(context: context, input: SdkHttpRequestBuilder(), next: next)
        } catch {
            next.finalError = error
        }
        try await next.verifyResult()
    }

    func test_case2() async throws {
        await setUp(availableCapacity: 500, maxCapacity: 500, maxRetriesBase: 2)
        next.testSteps = [
            TestStep(response: .httpError(502), expectedOutcome: .retryRequest, retryQuota: 495, delay: 1.0),
            TestStep(response: .httpError(502), expectedOutcome: .retryRequest, retryQuota: 490, delay: 2.0),
            TestStep(response: .httpError(502), expectedOutcome: .maxAttemptsExceeded, retryQuota: 490, delay: nil)
        ]
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
            print("Returning SUCCESS")
            return Output(httpResponse: HttpResponse(), output: TestOutputResponse())
        case .httpError(let statusCode):
            print("Returning FAILURE(\(statusCode))")
            throw TestHTTPError(statusCode: statusCode)
        }
    }

    func verifyResult(atEnd: Bool = true) async throws {
        guard let testStep = latestTestStep else { return }

        // Test available capacity
        let availableCapacity = await quota.availableCapacity
        print("CAPACITY: EXPECTED: \(testStep.retryQuota), ACTUAL: \(availableCapacity)")
        XCTAssertEqual(testStep.retryQuota, availableCapacity)

        // Test delay
        let actualDelay = sleeper.sleepTime.map(TimeInterval.init)?.map { $0 / 1_000_000_000.0 }
        print("DELAY: EXPECTED: \(String(describing: testStep.delay)), ACTUAL: \(String(describing: actualDelay))")
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
        guard let statusCodeValue = HttpStatusCode(rawValue: statusCode) else { fatalError() }
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
