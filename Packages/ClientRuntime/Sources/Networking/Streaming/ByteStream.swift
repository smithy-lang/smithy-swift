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
    var contentLength: Int? {get}
   
}

extension ByteStream {
    public func fromData(data: Data) -> DataContent {
        return DataContent(data: data)
    }
    
    public func fromFile(path: String) -> FileContent {
        return FileContent(path: path)
    }
    
    public func fromFile(fileHandle: FileHandle) -> FileContent {
        return FileContent(fileHandle: fileHandle)
    }
    
    public func fromString(string: String) -> StringContent {
        return StringContent(string: string)
    }
}

extension ByteStream {
    public func toBytes() -> ByteBuffer {
        switch self {
        case .buffer(let buffer):
            return buffer.toBytes()
        case .reader(let reader):
            let sink = reader.readFrom()
            let bytes = sink.readRemaining(limit: 4096)
            return bytes
        }
    }
}
