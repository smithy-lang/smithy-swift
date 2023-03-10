//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension EventStream {

    /// A header in an event stream message.
    /// Headers are used to convey metadata about the message.
    public struct Header: Equatable {

        /// The name of the header.
        public let name: String

        /// The value of the header.
        public let value: HeaderValue

        public init(name: String, value: HeaderValue) {
            self.name = name
            self.value = value
        }
    }
}

extension EventStream {

    /// The value of a header in an event stream message.
    /// Encoders and decoders may use this to determine how to encode or decode the header.
    public enum HeaderValue: Equatable {
        case bool(Bool)
        case byte(Int8)
        case int16(Int16)
        case int32(Int32)
        case int64(Int64)
        case data(Data)
        case string(String)
        case timestamp(Date)
        case uuid(UUID)
    }
}
