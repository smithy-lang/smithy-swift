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

typealias ISO8601Date = AWSDate<ISO8601DateFormatterContainer>
typealias RFC5322Date = AWSDate<RFC5322DateFormatterContainer>
typealias EpochSecondsDate = AWSDate<EpochSecondsDateFormatterContainer>

/*
 Generic formatted date representation.
 Wraps a Date object with the format information.
 */
public struct AWSDate<T: DateFormatterContainer>: Codable {
    let value: Date
    
    init(from value: Date) {
        self.value = value
    }
    
    public var stringValue: String {
        return String(T.encode(date: value))
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(T.encode(date: value))
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let encodedDate = try container.decode(T.EncodedValueType.self)
        
        guard let unwrappedDecodedDateValue = T.decode(encodedDate: encodedDate) else {
            throw ClientError.deserializationFailed(DateDecodingError.parseError)
        }
        
        self.value = unwrappedDecodedDateValue
    }
}
