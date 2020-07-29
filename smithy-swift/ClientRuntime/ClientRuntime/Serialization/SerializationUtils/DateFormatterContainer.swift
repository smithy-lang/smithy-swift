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
    var dateFormatters: [DateFormatterProtocol] { get }
}

struct RFC7231DateFormatterContainer: DateFormatterContainer {
    var dateFormatters: [DateFormatterProtocol] {
        return [getRFC7231DateFormatter()]
    }
}

// holds the two variants of ISO8601 DateFormatters in the order of priority
struct ISO8601DateFormatterContainer: DateFormatterContainer {
    // Need separate date formatters to handle optional fractional seconds
    var dateFormatters: [DateFormatterProtocol] {
        return [getISO8601DateFormatterWithFractionalSeconds(),
                getISO8601DateFormatterWithoutFractionalSeconds()]
    }
}

struct EposchSecondsDateFormatterContainer: DateFormatterContainer {
    var dateFormatters: [DateFormatterProtocol] {
        return [EposchSecondsDateFormatter()]
    }
}
