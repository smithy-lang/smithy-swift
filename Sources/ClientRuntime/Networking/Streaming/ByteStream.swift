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
}

extension ByteStream {
    public static func from(data: Data) -> ByteStream {
        return .data(data)
    }

    public static func from(fileHandle: FileHandle) -> ByteStream {
        return .stream(FileStream(fileHandle: fileHandle))
    }

    public static func from(stringValue: String) -> ByteStream {
        return .data(stringValue.data(using: .utf8) ?? Data())
    }

    public static func stream(from data: Data) -> ByteStream {
        return .stream(BufferedStream(data: data))
    }

    public static func defaultReader() -> ByteStream {
        return .stream(BufferedStream())
    }
}

extension ByteStream: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let data = try container.decode(Data.self)
        self = .data(data)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self)
    }
}

extension ByteStream: Equatable {
    public static func == (lhs: ByteStream, rhs: ByteStream) -> Bool {
        switch (lhs, rhs) {
        case (.data(let lhsData), .data(let rhsData)):
            return lhsData == rhsData
        case (.stream(let lhsStream), .stream(let rhsStream)):
            let lhsData = try? lhsStream.readToEnd()
            let rhsData = try? rhsStream.readToEnd()
            return lhsData == rhsData
        default:
            return false
        }
    }
}
