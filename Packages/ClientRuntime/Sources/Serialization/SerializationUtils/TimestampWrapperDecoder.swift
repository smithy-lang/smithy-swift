//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct TimestampWrapperDecoder {
    static func parseDateStringValue(_ dateStringValue: String, format: TimestampFormat) -> Date {
        let formatter: DateFormatter?
        switch(format) {
        case .epochSeconds:
            return Date(timeIntervalSince1970: TimeInterval(dateStringValue)!)
        case .dateTime:
            formatter = DateFormatter.iso8601DateFormatterWithoutFractionalSeconds
        case .httpDate:
            formatter = DateFormatter.rfc5322DateFormatter
        }
        return formatter!.date(from: dateStringValue)!
    }
}
