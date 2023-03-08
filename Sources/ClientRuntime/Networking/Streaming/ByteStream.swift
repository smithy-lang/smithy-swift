//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import AwsCommonRuntimeKit
import class Foundation.FileHandle

/// A stream of bytes.
public enum ByteStream {
    /// A stream of bytes represented as a `Data` object.
    case data(Data?)

    /// A stream of bytes represented as a `Stream` object.
    /// - Note: This representation is recommended for large streams of bytes.
    case stream(Stream)
}

extension ByteStream {
    /// Returns ByteStream from a Data object.
    /// - Parameter data: Data object to be converted to ByteStream.
    /// - Returns: ByteStream representation of the Data object.
    public static func from(data: Data) -> ByteStream {
        return .data(data)
    }

    /// Returns ByteStream from a FileHandle object.
    /// - Parameter fileHandle: FileHandle object to be converted to ByteStream.
    /// - Returns: ByteStream representation of the FileHandle object.
    public static func from(fileHandle: FileHandle) -> ByteStream {
        return .stream(FileStream(fileHandle: fileHandle))
    }

    /// Returns ByteStream from a String object.
    /// - Parameter stringValue: String object to be converted to ByteStream.
    /// - Returns: ByteStream representation of the String object.
    public static func from(stringValue: String) -> ByteStream {
        return .data(stringValue.data(using: .utf8) ?? Data())
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
            // swiftlint:disable force_try
            return try! lhsStream.isEqual(to: rhsStream)
            // swiftlint:enable force_try
        default:
            return false
        }
    }
}
