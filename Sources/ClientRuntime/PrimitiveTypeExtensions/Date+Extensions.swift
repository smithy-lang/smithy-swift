/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import struct Foundation.Date
public typealias Date = Foundation.Date

extension Date {
    /// Returns a new `Date` object with the same time as the receiver,
    /// but with the fractional seconds component set to zero.
    public func withoutFractionalSeconds() -> Date {
        let seconds = Int(self.timeIntervalSince1970)
        return Date(timeIntervalSince1970: Double(seconds))
    }
}
