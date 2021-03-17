//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct TimestampWrapperDecoder {
    static func parseDateStringValue(_ dateStringValue: String,
                                     format: TimestampFormat,
                                     codingPath: [CodingKey]? = nil) throws -> Date {
        let formatter: DateFormatter?
        switch format {
        case .epochSeconds:
            return Date(timeIntervalSince1970: TimeInterval(dateStringValue)!)
        case .dateTime:
            formatter = DateFormatter.iso8601DateFormatterWithoutFractionalSeconds
        case .httpDate:
            formatter = DateFormatter.rfc5322DateFormatter
        }

        guard let formattedDate = formatter!.date(from: dateStringValue) else {
            let context = DecodingError.Context(codingPath: codingPath ?? [],
                                                debugDescription: "Unable to parse: \(dateStringValue) to format \(format)")
            throw DecodingError.dataCorrupted(context)
        }
        return formattedDate
    }
}
