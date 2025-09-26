//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Date

/// A type that is used to provide the current time ("now") to callers.
///
/// Current time is accessed via the `WallClock.now` property.
///
/// The `WallClock.clockClosure` property may be modified or replaced for testing to simulate a different
/// current time.  The default closure returns the actual current time (i.e. by calling `Foundation.Date()`.)
@_spi(WallClock)
@preconcurrency
public struct WallClock {
    public static var clockClosure: @Sendable () -> Date = { Date() }

    // Prevents creation of an instance of this type.
    private init() {}

    public static var now: Date {
        clockClosure()
    }
}
