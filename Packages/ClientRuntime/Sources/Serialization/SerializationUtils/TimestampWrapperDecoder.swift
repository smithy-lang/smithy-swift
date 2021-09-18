//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct TimestampWrapperDecoder {
    static public func parseDateStringValue(_ dateStringValue: String,
                                            format: TimestampFormat,
                                            codingPath: [CodingKey]? = nil) throws -> Date {
        var formatter: DateFormatter?
        switch format {
        case .epochSeconds:
            return Date(timeIntervalSince1970: TimeInterval(dateStringValue)!)
        case .dateTime:
            formatter = DateFormatter.iso8601DateFormatterWithoutFractionalSeconds
            if let formattedDate = formatter!.date(from: dateStringValue) {
                return formattedDate
            } else {
                formatter = DateFormatter.iso8601DateFormatterWithFractionalSeconds
            }

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
