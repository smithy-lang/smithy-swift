//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data

/// A message in an event stream that can be sent or received.
public struct Message: Equatable, Sendable {

    /// The headers associated with the message.
    public let headers: [Header]

    /// The payload associated with the message.
    public let payload: Data

    public init(headers: [Header] = [], payload: Data = .init()) {
        self.headers = headers
        self.payload = payload
    }
}

extension Message: CustomDebugStringConvertible {
    public var debugDescription: String {
        let headers = self.headers.map { "\($0.name): \($0.value)" }.joined(separator: "\n")
        return """
        EventStream.Message(
            headers: [
            \(headers)
            ],
            payload: \(String(data: payload, encoding: .utf8) ?? "<invalid>"
        )
        """
    }
}

extension Array where Element == Header {
    /// Returns the value of the header with the given name if it exists.
    /// - Parameter name: The name of the header to retrieve.
    public func value(name: String) -> HeaderValue? {
        return self.first(where: { $0.name == name })?.value
    }
}
