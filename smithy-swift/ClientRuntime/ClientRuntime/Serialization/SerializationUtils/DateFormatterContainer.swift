//
// Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.
// A copy of the License is located at
//
// http://aws.amazon.com/apache2.0
//
// or in the "license" file accompanying this file. This file is distributed
// on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
// express or implied. See the License for the specific language governing
// permissions and limitations under the License.
//

import Foundation

public protocol DateFormatterContainer {
    associatedtype EncodedValueType: Codable
    static var dateFormatters: [DateFormatterProtocol] { get }
    static func encode(date: Date) -> EncodedValueType
    static func decode(encodedDate: EncodedValueType) -> Date?
}

extension DateFormatterContainer {
    static func encode(date: Date) -> String {
        return dateFormatters[0].string(from: date)
    }
    
    static func decode(encodedDate: String) -> Date? {
        // use the formatters in order of priority
        var decodedValue: Date?
        for dateFormatter in dateFormatters {
            decodedValue = dateFormatter.date(from: encodedDate)
            if (decodedValue != nil) {
                break
            }
        }
        return decodedValue
    }
}

struct RFC5322DateFormatterContainer: DateFormatterContainer {
    typealias EncodedValueType = String
    
    static var dateFormatters: [DateFormatterProtocol] {
        return [DateFormatter.rfc5322DateFormatter]
    }
}

// holds the two variants of ISO8601 DateFormatters in the order of priority
struct ISO8601DateFormatterContainer: DateFormatterContainer {
    typealias EncodedValueType = String
    
    // Need separate date formatters to handle optional fractional seconds
    static var dateFormatters: [DateFormatterProtocol] {
        return [DateFormatter.iso8601DateFormatterWithFractionalSeconds,
                DateFormatter.iso8601DateFormatterWithoutFractionalSeconds]
    }
}

struct EpochSecondsDateFormatterContainer: DateFormatterContainer {
    typealias EncodedValueType = Double
    
    static var dateFormatters: [DateFormatterProtocol] {
        return [DateFormatter.epochSecondsDateFormatter]
    }
    
    static func encode(date: Date) -> EncodedValueType {
        return EpochSecondsDateFormatter().double(from: date)
    }
    
    static func decode(encodedDate: EncodedValueType) -> Date? {
        // use the formatters in order of priority
        let decodedValue = EpochSecondsDateFormatter().date(from: encodedDate)
        return decodedValue
    }
}
