//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension EventStream {

    /// A message in an event stream that can be sent or received.
    public struct Message: Equatable {

        /// The headers associated with the message.
        public let headers: [EventStream.Header]

        /// The payload associated with the message.
        public let payload: Data

        public init(headers: [EventStream.Header] = [], payload: Data = .init()) {
            self.headers = headers
            self.payload = payload
        }
    }
}
