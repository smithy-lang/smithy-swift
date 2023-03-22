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

extension EventStream.Message: CustomDebugStringConvertible {
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

extension Array where Element == EventStream.Header {
    public func toHeaders() -> Headers {
        var headers = Headers()
        for header in self {
            switch header.value {
            case .bool(let value):
                headers.add(name: header.name, value: "\(value)")
            case .byte(let value):
                headers.add(name: header.name, value: "\(value)")
            case .int16(let value):
                headers.add(name: header.name, value: "\(value)")
            case .int32(let value):
                headers.add(name: header.name, value: "\(value)")
            case .int64(let value):
                headers.add(name: header.name, value: "\(value)")
            case .byteArray(let value):
                headers.add(name: header.name, value: value.base64EncodedString())
            case .string(let value):
                headers.add(name: header.name, value: value)
            case .timestamp(let value):
                headers.add(name: header.name, value: "\(value.timeIntervalSince1970)")
            case .uuid(let value):
                headers.add(name: header.name, value: value.uuidString)
            }
        }
        return headers
    }
}

extension Array where Element == EventStream.Header {
    public func value(name: String) -> EventStream.HeaderValue? {
        return self.first(where: { $0.name == name })?.value
    }
}
