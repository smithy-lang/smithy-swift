//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Calculates the time for the next retry, and whether waiting should continue.
/// Upon creation, the scheduler will allow an immediate request.
/// After the first request, further requests are scheduled per the retry strategy formula
/// published in the Smithy specification:
/// https://smithy.io/2.0/additional-specs/waiters.html#waiter-retries
final class WaiterScheduler {
    /// The minimum delay between retries while waiting.
    let minDelay: TimeInterval
    /// The maximum delay between retries while waiting.
    let maxDelay: TimeInterval
    /// The maximum time to spend waiting for the retry to succeed, before a timeout error is thrown.
    let maxWaitTime: TimeInterval

    /// Returns the current Date.  For testing, this closure may be replaced to provide simulated time.
    var now: () -> Date = { Date() }

    /// The Date when the next request should take place after a retry.
    var nextRequestDate = Date.distantPast

    /// The number of requests ("attempts") that have been made by this waiter.
    private(set) var attempts = 0

    /// Set to true once waiting has expired and no further attempts should be made.
    private(set) var isExpired = false

    /// Set to the Date of the start of the first request.
    /// Used to track the total time elapsed when waiting.
    private var startDate = Date.distantPast

    init(
        minDelay: TimeInterval,
        maxDelay: TimeInterval,
        maxWaitTime: TimeInterval
    ) {
        self.minDelay = minDelay
        self.maxDelay = maxDelay
        self.maxWaitTime = maxWaitTime
    }

    var currentDelay: TimeInterval {
        max(0.0, nextRequestDate.timeIntervalSince(now()))
    }

    private var remainingTime: TimeInterval {
        let totalElapsedTime = now().timeIntervalSince(startDate)
        return maxWaitTime - totalElapsedTime
    }

    func updateAfterRetry() {
        // Update attempt number; the first request is 1.
        attempts += 1

        // The first time this method is called, set startDate
        // which is used to determine total elapsed time.
        if attempts == 1 {
            startDate = now()
        }

        // Calculate & set the delay using the formula in the Smithy retry strategy:
        // https://smithy.io/2.0/additional-specs/waiters.html#waiter-retries
        var delay: TimeInterval
        let attemptCeiling = Int(((log(maxDelay / minDelay) / log(2.0)) + 1.0).rounded(.towardZero))
        if attempts > attemptCeiling {
            delay = maxDelay
        } else {
            delay = minDelay * pow(2.0, Double(attempts - 1))
        }
        delay = TimeInterval.random(in: minDelay...delay)
        if remainingTime - delay <= minDelay {
            delay = remainingTime - minDelay
            isExpired = true
        }

        // Determine & store the "wall clock date" of the next request.
        nextRequestDate = now().addingTimeInterval(delay)
    }
}
