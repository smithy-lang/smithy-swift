//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.TimeInterval
import struct Foundation.Date
import func Foundation.pow

actor ClientSideRateLimiter : Sendable {

    // these are constants defined in Retry Behavior 2.0
    let minFillRate: Double = 0.5
    let minCapacity: Double = 1.0
    let smooth: Double = 0.8
    let beta = 0.7
    let scaleConstant = 0.4

    // these are state variables explicitly declared in Retry Behavior 2.0
    var fillRate: Double = 0.0
    var maxCapacity: Double = 0.0
    var currentCapacity: Double = 0.0
    var lastTimestamp: TimeInterval? = 0.0
    var enabled = false
    var measuredTXRate: Double = 0.0
    var lastTXRateBucket: Double
    var requestCount: Int = 0
    var lastMaxRate: Double = 0.0
    var lastThrottleTime: TimeInterval

    // not explicitly included as state in Retry Behavior 2.0, but it said to cache the
    // value when lastMaxRate changes
    var timeWindow: Double = 0.0

    // Returns the current time when called.
    // Exposed so time may be mocked for testing.
    var clock: () -> TimeInterval

    /// Creates a new client-side rate limiter.
    ///
    /// Parameters are for use during testing.  To create this type for actual use, call `.init()`.
    /// - Parameters:
    ///   - lastMaxRate: The last max rate to set.  For testing use only.
    ///   - lastThrottleTime: The last throttle time to set.  For testing use only.
    ///   - clock: An anonymous closure that provides the current time in the form of a timestamp.  Defaults to actual time.  For testing use only.
    init(
        lastMaxRate: Double = 0.0,
        lastThrottleTime: TimeInterval? = nil,
        clock: @escaping () -> TimeInterval = { Date().timeIntervalSinceReferenceDate }
    ) {
        self.lastMaxRate = lastMaxRate
        self.lastThrottleTime = lastThrottleTime ?? clock()
        self.lastTXRateBucket = Self.floor(clock())
        self.clock = clock
    }

    // The following functions are built exactly as described in Retry Behavior 2.0.

    func tokenBucketAcquire(amount: Double) -> TimeInterval? {
        if !enabled { return nil }
        tokenBucketRefill()
        if amount <= currentCapacity {
            currentCapacity -= amount
            return nil
        } else {
            let delay = (amount - currentCapacity) / fillRate
            currentCapacity -= amount
            return delay
        }
    }

    private func tokenBucketRefill() {
        let timestamp = clock()
        guard let lastTimestamp = lastTimestamp else {
            self.lastTimestamp = timestamp
            return
        }
        let fillAmount = (timestamp - lastTimestamp) * fillRate
        currentCapacity = min(maxCapacity, currentCapacity + fillAmount)
        self.lastTimestamp = timestamp
    }

    private func tokenBucketUpdateRate(newRPS: Double) {
        tokenBucketRefill()
        fillRate = max(newRPS, minFillRate)
        maxCapacity = max(newRPS, minCapacity)
        currentCapacity = min(currentCapacity, maxCapacity)
    }

    private func tokenBucketEnable() {
        enabled = true
    }

    private func updateMeasuredRate() {
        let t = clock()
        let timeBucket = Self.floor(t * 2.0) / 2.0
        requestCount += 1
        if timeBucket > lastTXRateBucket {
            let currentRate = Double(requestCount) / (timeBucket - lastTXRateBucket)
            measuredTXRate = (currentRate * smooth) + (measuredTXRate * (1.0 - smooth))
            requestCount = 0
            lastTXRateBucket = timeBucket
        }
    }

    // Exposed internally for use while testing.
    func updateClientSendingRate(isThrottling: Bool) {
        updateMeasuredRate()
        let calculatedRate: Double
        if isThrottling {
            let rateToUse = enabled ? min(measuredTXRate, fillRate) : measuredTXRate
            lastMaxRate = rateToUse
            calculateTimeWindow()
            lastThrottleTime = clock()
            calculatedRate = cubicThrottle(rateToUse: rateToUse)
            tokenBucketEnable()
        } else {
            calculateTimeWindow()
            calculatedRate = cubicSuccess(timestamp: clock())
        }
        let newRate = min(calculatedRate, 2.0 * measuredTXRate)
        tokenBucketUpdateRate(newRPS: newRate)
    }

    // Exposed internally for use while testing.
    func calculateTimeWindow() {
        timeWindow = pow(lastMaxRate * (1.0 - beta) / scaleConstant, 1.0 / 3.0)
    }

    // Exposed internally for use while testing.
    func cubicSuccess(timestamp: TimeInterval) -> Double {
        let dt = timestamp - lastThrottleTime
        return scaleConstant * pow(dt - timeWindow, 3.0) + lastMaxRate
    }

    // Exposed internally for use while testing.
    func cubicThrottle(rateToUse: Double) -> Double {
        return rateToUse * beta
    }

    private static func floor(_ time: TimeInterval) -> TimeInterval {
        time.rounded(.down)
    }

    // The following functions are not described in Retry Behavior 2.0 but are
    // used to set test conditions.

    func setLastMaxRate(_ newValue: Double) { lastMaxRate = newValue }

    func setLastThrottleTime(_ newValue: Double) { lastThrottleTime = newValue }

    func setClock(_ newClock: @escaping () -> TimeInterval) { clock = newClock }
}
