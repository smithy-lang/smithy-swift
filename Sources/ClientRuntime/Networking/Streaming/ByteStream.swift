//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import AwsCommonRuntimeKit
import class Foundation.FileHandle

public enum ByteStream {
    case data(Data?)
    case stream(Stream)
    case none

    // Read Data
    public func readData() async throws -> Data? {
        switch self {
        case .data(let data):
            return data
        case .stream(let stream):
            if stream.isSeekable {
                try stream.seek(toOffset: 0)
            }
            return try await stream.readToEndAsync()
        case .none:
            return nil
        }
    }

    // Equatable Conformance
    public static func ==(lhs: ByteStream, rhs: ByteStream) -> Bool {
        switch (lhs, rhs) {
        case (.data(let lhsData), .data(let rhsData)):
            return lhsData == rhsData
        case (.stream(let lhsStream), .stream(let rhsStream)):
            return lhsStream === rhsStream
        default:
            return false
        }
    }

    // Codable Conformance
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let data = try? container.decode(Data.self) {
            self = .data(data)
        } else {
            let stream = try container.decode(Stream.self)
            self = .stream(stream)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .data(let data):
            try container.encode(data)
        case .stream(let stream):
            try container.encode(stream)
        }
    }
}

extension ByteStream {

    // Static property for an empty ByteStream
    static var empty: ByteStream {
        .data(nil)
    }

    // Returns true if the byte stream is empty
    var isEmpty: Bool {
        switch self {
        case .data(let data):
            return data?.isEmpty ?? true
        case .stream(let stream):
            return stream.isEmpty
         case .none:
            return true
        }
    }
}

extension ByteStream: CustomDebugStringConvertible {

    public var debugDescription: String {
        switch self {
        case .data(let data):
            return data.map { String(describing: $0) } ?? "nil (Data)"
        case .stream(let stream):
            if stream.isSeekable {
                let currentPosition = stream.position
                defer { try? stream.seek(toOffset: currentPosition) }
                return (try? stream.readToEnd().description) ?? "Stream not readable"
            } else {
                return "Stream (non-seekable, Position: \(stream.position), Length: \(stream.length ?? -1))"
            }
        }
    }
}
