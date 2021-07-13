//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import AwsCommonRuntimeKit
import class Foundation.FileHandle

public enum ByteStream {
    case buffer(Buffer)
    case reader(Reader)
}

public protocol Buffer: Stream {
    func toBytes() -> ByteBuffer
}

public protocol Reader: Stream {
    func readFrom() -> StreamSink
}

public protocol Stream {
    var contentLength: Int64? {get}
}

extension ByteStream {
    public static func fromData(data: Data) -> ByteStream {
        return .buffer(DataContent(data: data))
    }
    
    public static func fromFile(path: String) -> ByteStream {
        return .buffer(FileContent(path: path))
    }
    
    public static func fromFile(fileHandle: FileHandle) -> ByteStream {
        return .buffer(FileContent(fileHandle: fileHandle))
    }
    
    public static func fromString(string: String) -> ByteStream {
        return .buffer(StringContent(string: string))
    }
}

extension ByteStream {
    public func toBytes() -> ByteBuffer {
        switch self {
        case .buffer(let buffer):
            return buffer.toBytes()
        case .reader(let reader):
            let sink = reader.readFrom()
            let bytes = sink.readRemaining(limit: Int.max)
            return bytes
        }
    }
}

extension ByteStream: Equatable {
    public static func == (lhs: ByteStream, rhs: ByteStream) -> Bool {
        switch (lhs, rhs) {
        case (let .reader(unwrappedLhsReader), let .reader(unwrappedRhsReader)):
            return unwrappedLhsReader.readFrom() === unwrappedRhsReader.readFrom()
        case (let .buffer(lhsBuffer), let .buffer(rhsBuffer)):
            return lhsBuffer.toBytes() === rhsBuffer.toBytes()
        default:
            return false
        }
    }
}

extension ByteStream: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let buffer = try container.decode(Data.self)
        self = .buffer(buffer)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.toBytes().toData())
    }
}

extension Data : Buffer {
    public func toBytes() -> ByteBuffer {
        return ByteBuffer(data: self)
    }
    
    public var contentLength: Int64? {
        return Int64(count)
    }
}
