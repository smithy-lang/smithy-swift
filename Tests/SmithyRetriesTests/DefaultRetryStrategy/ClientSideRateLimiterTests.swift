//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
@testable import SmithyRetries
@testable import ClientRuntime

final class ClientSideRateLimiterTests: XCTestCase {
    private var subject: ClientSideRateLimiter!

    // MARK: - CUBIC test cases

    func test_case1() async throws {
        subject = ClientSideRateLimiter(lastMaxRate: 10.0, lastThrottleTime: 5.0, clock: { 5.0 })
        let testSteps: [TestStep] = [
            .init(response: .success, timestamp: 5.0, calculatedRate: 7.0),
            .init(response: .success, timestamp: 6.0, calculatedRate: 9.64893600966),
            .init(response: .success, timestamp: 7.0, calculatedRate: 10.000030849917364),
            .init(response: .success, timestamp: 8.0, calculatedRate: 10.453284520772092),
            .init(response: .success, timestamp: 9.0, calculatedRate: 13.408697022224185),
            .init(response: .success, timestamp: 10.0, calculatedRate: 21.26626835427364),
            .init(response: .success, timestamp: 11.0, calculatedRate: 36.425998516920465)
        ]
        await runTest(testSteps: testSteps)
    }

    func test_case2() async throws {
        subject = ClientSideRateLimiter(lastMaxRate: 10.0, lastThrottleTime: 5.0, clock: { 5.0 })
        let testSteps: [TestStep] = [
            .init(response: .success, timestamp: 5.0, calculatedRate: 7.0),
            .init(response: .success, timestamp: 6.0, calculatedRate: 9.64893600966),
            .init(response: .throttle, timestamp: 7.0, calculatedRate: 6.754255206761999),
            .init(response: .throttle, timestamp: 8.0, calculatedRate: 4.727978644733399),
            .init(response: .success, timestamp: 9.0, calculatedRate: 6.606547753887045),
            .init(response: .success, timestamp: 10.0, calculatedRate: 6.763279816944947),
            .init(response: .success, timestamp: 11.0, calculatedRate: 7.598174833907107),
            .init(response: .success, timestamp: 12.0, calculatedRate: 11.511232804773524)
        ]
        await runTest(testSteps: testSteps)
    }

    // MARK: - End-to-end test cases

    func test_case3() async throws {
        subject = ClientSideRateLimiter(clock: { 0.0 })
        let testSteps: [TestStep] = [
            .init(response: .success, timestamp: 0.2, measuredTXRate: 0.0, newTokenBucketRate: 0.5),
            .init(response: .success, timestamp: 0.4, measuredTXRate: 0.0, newTokenBucketRate: 0.5),
            .init(response: .success, timestamp: 0.6, measuredTXRate: 4.8, newTokenBucketRate: 0.5),
            .init(response: .success, timestamp: 0.8, measuredTXRate: 4.8, newTokenBucketRate: 0.5),
            .init(response: .success, timestamp: 1.0, measuredTXRate: 4.16, newTokenBucketRate: 0.5),
            .init(response: .success, timestamp: 1.2, measuredTXRate: 4.16, newTokenBucketRate: 0.6912),
            .init(response: .success, timestamp: 1.4, measuredTXRate: 4.16, newTokenBucketRate: 1.0976),
            .init(response: .success, timestamp: 1.6, measuredTXRate: 5.632, newTokenBucketRate: 1.6384),
            .init(response: .success, timestamp: 1.8, measuredTXRate: 5.632, newTokenBucketRate: 2.3328),
            .init(response: .throttle, timestamp: 2.0, measuredTXRate: 4.3264, newTokenBucketRate: 3.02848),
            .init(response: .success, timestamp: 2.2, measuredTXRate: 4.3264, newTokenBucketRate: 3.486639)
        ]
        await runTest(testSteps: testSteps)
    }

    private func runTest(testSteps: [TestStep]) async {
        await subject.calculateTimeWindow()
        var lastCalculatedRate: TimeInterval = 0.0
        for testStep in testSteps {
            await subject.setClock { testStep.timestamp }

            // Cubic tests require a little setup before figuring the value.
            // See https://github.com/aws/aws-sdk-java/blob/master/aws-java-sdk-core/src/test/java/com/amazonaws/internal/TokenBucketCubicTest.java
            // for Java's test setup, which is followed here as well.
            if let expectedCalculatedRate = testStep.calculatedRate {
                switch testStep.response {
                case .success:
                    await subject.calculateTimeWindow()
                    lastCalculatedRate = await subject.cubicSuccess(timestamp: testStep.timestamp)
                case .throttle:
                    await subject.setLastMaxRate(lastCalculatedRate)
                    await subject.calculateTimeWindow()
                    await subject.setLastThrottleTime(testStep.timestamp)
                    lastCalculatedRate = await subject.cubicThrottle(rateToUse: lastCalculatedRate)
                }
                XCTAssertEqual(lastCalculatedRate, expectedCalculatedRate, accuracy: 0.001, file: testStep.file, line: testStep.line)
            }

            // End-to-end tests require updating client send rate and current time (see above) between steps.
            if testStep.measuredTXRate != nil || testStep.newTokenBucketRate != nil {
                await subject.updateClientSendingRate(isThrottling: testStep.response == .throttle)
            }
            if let measuredTXRate = testStep.measuredTXRate {
                let actualRate = await subject.measuredTXRate
                XCTAssertEqual(actualRate, measuredTXRate, accuracy: 0.001, file: testStep.file, line: testStep.line)
            }
            if let newTokenBucketRate = testStep.newTokenBucketRate {
                let actualRate = await subject.fillRate
                XCTAssertEqual(actualRate, newTokenBucketRate, accuracy: 0.001, file: testStep.file, line: testStep.line)
            }
        }
    }
}

private struct TestStep {

    enum Response {
        case success
        case throttle
    }

    let response: Response
    let timestamp: TimeInterval
    let calculatedRate: Double?
    let measuredTXRate: Double?
    let newTokenBucketRate: Double?
    let file: StaticString
    let line: UInt

    init(response: Response, timestamp: TimeInterval, calculatedRate: Double? = nil, measuredTXRate: Double? = nil, newTokenBucketRate: Double? = nil, file: StaticString = #file, line: UInt = #line) {
        self.response = response
        self.timestamp = timestamp
        self.calculatedRate = calculatedRate
        self.measuredTXRate = measuredTXRate
        self.newTokenBucketRate = newTokenBucketRate
        self.file = file
        self.line = line
    }
}
