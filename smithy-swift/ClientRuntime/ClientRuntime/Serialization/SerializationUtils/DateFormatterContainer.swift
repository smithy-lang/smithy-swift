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
    public static func encode(date: Date) -> String {
        return dateFormatters[0].string(from: date)
    }
    
    public static func decode(encodedDate: String) -> Date? {
        // use the formatters in order of priority
        for dateFormatter in dateFormatters {
            if let decodedValue = dateFormatter.date(from: encodedDate) {
                return decodedValue
            }
        }
        return nil
    }
}

public struct RFC5322DateFormatterContainer: DateFormatterContainer {
    public typealias EncodedValueType = String
    
    public static var dateFormatters: [DateFormatterProtocol] {
        return [DateFormatter.rfc5322DateFormatter]
    }
}

// holds the two variants of ISO8601 DateFormatters in the order of priority
public struct ISO8601DateFormatterContainer: DateFormatterContainer {
    public typealias EncodedValueType = String
    
    // Need separate date formatters to handle optional fractional seconds
    public static var dateFormatters: [DateFormatterProtocol] {
        return [DateFormatter.iso8601DateFormatterWithFractionalSeconds,
                DateFormatter.iso8601DateFormatterWithoutFractionalSeconds]
    }
}

public struct EpochSecondsDateFormatterContainer: DateFormatterContainer {
    public typealias EncodedValueType = Double
    
    public static var dateFormatters: [DateFormatterProtocol] {
        return [DateFormatter.epochSecondsDateFormatter]
    }
    
    public static func encode(date: Date) -> EncodedValueType {
        return EpochSecondsDateFormatter().double(from: date)
    }
    
    public static func decode(encodedDate: EncodedValueType) -> Date? {
        let decodedValue = EpochSecondsDateFormatter().date(from: encodedDate)
        return decodedValue
    }
}
