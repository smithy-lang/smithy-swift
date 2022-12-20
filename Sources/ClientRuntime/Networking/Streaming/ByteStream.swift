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
}

extension ByteStream {
    public static func from(data: Data) -> ByteStream {
        return .buffer(ByteBuffer(data: data))
    }
    
    public static func from(fileHandle: FileHandle) -> ByteStream {
        return .buffer(fileHandle.toByteBuffer())
    }
    
    public static func from(stringValue: String) -> ByteStream {
        return .buffer(stringValue.toByteBuffer())
    }
}

extension ByteStream {
    public func toBytes() -> ByteBuffer {
        switch self {
        case .buffer(let buffer):
            return buffer
        }
    }
    
    public static func defaultReader() -> ByteStream {
        return .buffer(ByteBuffer(size: 0))
    }
}

extension ByteStream: Equatable {
    public static func == (lhs: ByteStream, rhs: ByteStream) -> Bool {
        switch (lhs, rhs) {
        case (let .buffer(lhsBuffer), let .buffer(rhsBuffer)):
            return lhsBuffer.getData() == rhsBuffer.getData()
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
        try container.encode(self.toBytes().getData())
    }
}
