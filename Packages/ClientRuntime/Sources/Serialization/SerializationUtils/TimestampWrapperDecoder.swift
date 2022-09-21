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
        var formattedDate: Date?

        switch format {
        case .epochSeconds:
            formattedDate = Date(timeIntervalSince1970: TimeInterval(dateStringValue)!)
        case .dateTime:
            if let date = DateFormatter.iso8601DateFormatterWithoutFractionalSeconds.date(from: dateStringValue) {
                formattedDate = date
            } else if let date = DateFormatter.iso8601DateFormatterWithFractionalSeconds.date(from: dateStringValue) {
                formattedDate = date
            }
        case .httpDate:
            formattedDate = DateFormatter.rfc5322DateFormatter.date(from: dateStringValue)
        }

        guard let formattedDate = formattedDate else {
            let debugDescription = "Unable to parse: \(dateStringValue) to format \(format)"
            let context = DecodingError.Context(codingPath: codingPath ?? [], debugDescription: debugDescription)
            throw DecodingError.dataCorrupted(context)
        }
        return formattedDate
    }    
}
