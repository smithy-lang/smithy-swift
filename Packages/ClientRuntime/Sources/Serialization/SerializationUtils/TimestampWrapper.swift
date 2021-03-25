//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct TimestampWrapper: Encodable {
    public let date: Date
    public let format: TimestampFormat
    
    public init(_ date: Date, format: TimestampFormat) {
        self.date = date
        self.format = format
    }
    
    func dateFormatted() -> String {
        switch format {
        case .epochSeconds:
            return "\(date.timeIntervalSince1970)"
        case .dateTime:
            return date.iso8601WithoutFractionalSeconds()
        case .httpDate:
            return date.rfc5322()
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(dateFormatted())
    }
}
