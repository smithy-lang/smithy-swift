//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension Date {
    /// Returns a date that to use in tests, using the provided components.
    /// The date is built using the iso8601 calendar and in the UTC timezone to ensure date comparisons are consistent
    /// regardless of location of the machines physically running the tests.
    static func makeDateForTests(
        day: Int,
        month: Int,
        year: Int,
        hour: Int,
        minute: Int,
        second: Int,
        milliseconds: Int? = nil
    ) -> Date {
        let components = DateComponents(
            calendar: .init(identifier: .iso8601),
            timeZone: TimeZone(abbreviation: "GMT")!,
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute,
            second: second,
            nanosecond: milliseconds.map { $0 * 1_000_000 }
        )
        return components.date!
    }
}
