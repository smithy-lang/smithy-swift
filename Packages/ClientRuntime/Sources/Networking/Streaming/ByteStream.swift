//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import AwsCommonRuntimeKit
import class Foundation.FileHandle

public enum ByteStream {
    case buffer(ByteBuffer)
    case reader(StreamReader)
}


extension ByteStream {
    public static func fromData(data: Data) -> ByteStream {
        return .buffer(ByteBuffer(data: data))
    }
    
    public static func fromFile(path: String) -> ByteStream {
        return .buffer(FileContent(path: path).toBytes())
    }
    
    public static func fromFile(fileHandle: FileHandle) -> ByteStream {
        return .buffer(FileContent(fileHandle: fileHandle).toBytes())
    }
    
    public static func fromString(string: String) -> ByteStream {
        return .buffer(StringContent(underlyingStringBuffer: string).toBytes())
    }
}

extension ByteStream {
    public func toBytes() -> ByteBuffer {
        switch self {
        case .buffer(let buffer):
            return buffer
        case .reader(let reader):
            let bytes = reader.read(maxBytes: nil)
            return bytes
        }
    }
}

extension ByteStream: Equatable {
    public static func == (lhs: ByteStream, rhs: ByteStream) -> Bool {
        switch (lhs, rhs) {
        case (let .reader(unwrappedLhsReader), let .reader(unwrappedRhsReader)):
            return unwrappedLhsReader === unwrappedRhsReader
        case (let .buffer(lhsBuffer), let .buffer(rhsBuffer)):
            return lhsBuffer.toByteArray() == rhsBuffer.toByteArray()
        default:
            return false
        }
    }
}

extension ByteStream: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let data = try container.decode(Data.self)
        self = .buffer(ByteBuffer(data: data))
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.toBytes().toData())
    }
}

