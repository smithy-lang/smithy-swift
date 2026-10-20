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

/// Covers the token bucket when acquires outpace the fill rate. Regression:
/// the bucket used to consume a token on the insufficient-capacity branch,
/// driving `currentCapacity` negative and over-throttling under sustained
/// load.
final class ClientSideRateLimiterConcurrencyTests: XCTestCase {

    /// A mutable virtual clock so the test controls time deterministically.
    final class MutableClock: @unchecked Sendable {
        private let lock = NSLock()
        private var t: TimeInterval
        init(_ start: TimeInterval) { t = start }
        func now() -> TimeInterval { lock.lock(); defer { lock.unlock() }; return t }
        func set(_ v: TimeInterval) { lock.lock(); t = v; lock.unlock() }
    }

    private func makeEnabledLimiter(
        fillRate: Double,
        capacity: Double,
        clock: MutableClock
    ) async -> ClientSideRateLimiter {
        let limiter = ClientSideRateLimiter(clock: { clock.now() })
        await limiter.setTokenBucketForTesting(fillRate: fillRate, capacity: capacity)
        return limiter
    }

    /// `tokenBucketTryAcquire` must never drive capacity negative: when no
    /// token is available it returns a wait without consuming one.
    func test_burstTryAcquire_neverDrivesCapacityNegative() async throws {
        let clock = MutableClock(1000.0)
        // Start empty so every try takes the insufficient-capacity branch.
        let limiter = await makeEnabledLimiter(fillRate: 20.0, capacity: 0.0, clock: clock)

        // Back-to-back tries with no time advancing — the concurrent case.
        for _ in 0..<30 {
            let wait = await limiter.tokenBucketTryAcquire(amount: 1.0)
            XCTAssertNotNil(wait, "Empty bucket should not grant a token.")
            let cap = await limiter.currentCapacity
            XCTAssertGreaterThanOrEqual(cap, 0.0, "currentCapacity went negative (\(cap)).")
        }
    }

    /// After enough time elapses to refill a token, `tokenBucketTryAcquire`
    /// grants it (returns nil) and consumes exactly one token.
    func test_tryAcquire_grantsAfterRefill() async throws {
        let clock = MutableClock(2000.0)
        let limiter = await makeEnabledLimiter(fillRate: 20.0, capacity: 0.0, clock: clock)

        // Empty at t=2000: must report a positive wait, no token taken.
        let wait = await limiter.tokenBucketTryAcquire(amount: 1.0)
        XCTAssertNotNil(wait)
        XCTAssertGreaterThan(wait ?? 0, 0)

        // Advance past the wait (1 token / 20 rps = 0.05s; advance 1s).
        clock.set(2001.0)
        let granted = await limiter.tokenBucketTryAcquire(amount: 1.0)
        XCTAssertNil(granted, "Bucket did not grant a token after refill.")
        let cap = await limiter.currentCapacity
        XCTAssertGreaterThanOrEqual(cap, 0.0)
        XCTAssertLessThanOrEqual(cap, 20.0)
    }
}
