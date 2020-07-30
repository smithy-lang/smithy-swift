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

struct EpochSecondsDate: Codable {
    var value: Date
    var dateFormatterContainer: DateFormatterContainer = EpochSecondsDateFormatterContainer()
    
    public var stringValue: String {
       get { return dateFormatterContainer.dateFormatters[0].string(from: value) }
    }
    
    init(from value: Date) {
        self.value = value
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        // use the formatter with top priority
        try container.encode(stringValue)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let text = try container.decode(String.self)
        
        // use the formatters in order of priority
        var decodedValue: Date?
        for dateFormatter in dateFormatterContainer.dateFormatters {
            decodedValue = dateFormatter.date(from: text)
            if (decodedValue != nil) {
                break
            }
        }
        guard let nonOptionalDecodedValue = decodedValue else {
            // TODO:: SDKError<Any> looks wierd?
            throw SdkError<Any>.client(ClientError.deserializationFailed(DateDecodingError.parseError))
        }
        self.value = nonOptionalDecodedValue
    }
}
