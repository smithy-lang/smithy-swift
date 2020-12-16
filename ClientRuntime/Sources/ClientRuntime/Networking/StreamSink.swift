/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import AwsCommonRuntimeKit
import class Foundation.FileHandle
import struct Foundation.Data
import class Foundation.FileManager

//TODO: handle backpressure more thoroughly to allow for indication that they are ready for more
@available(*, message: "This streaming interface is unstable currently for dynamic streaming")
public protocol StreamSink: class {
    func receiveData(readFrom buffer: ByteBuffer)
    func onError(error: StreamError)
}

public class DataStreamSink: StreamSink {
    public var data: Data
    public var error: StreamError?
    
    init(data: Data = Data()) {
        self.data = data
    }
    
    public func receiveData(readFrom buffer: ByteBuffer) {
        data.append(buffer.toData())
    }
    
    public func onError(error: StreamError) {
        self.error = error
    }
}

public class FileStreamSink: StreamSink {
    public var fileHandle: FileHandle?
    public var error: StreamError?
    
    init(filePath: String) {
       
        let fileManager = FileManager.default
        fileManager.createFile(atPath: filePath, contents: nil)
        self.fileHandle = FileHandle(forWritingAtPath: filePath)
    }
    
    public func receiveData(readFrom buffer: ByteBuffer) {
        fileHandle?.write(buffer.toData())
    }
    
    public func onError(error: StreamError) {
        self.error = error
    }
}

public enum StreamSinkProvider {
    case provider(StreamSink)
}

extension StreamSinkProvider {
    public static func defaultDataProvider() -> StreamSinkProvider {
        return .provider(DataStreamSink())
    }
    
    public static func defaultFileProvider(filePath: String) -> StreamSinkProvider {
        return .provider(FileStreamSink(filePath: filePath))
    }
    
    public func toData() -> Data? {
        let dataStream = self.unwrap() as? DataStreamSink
        return dataStream?.data
    }
    
    public func toFile() -> FileHandle? {
        let fileStream = self.unwrap() as? FileStreamSink
        return fileStream?.fileHandle
    }
    
    /// This function is a util to enhance developer experience. This enum only has one case so this function
    /// provides an easy way to unwrap the single case to get the associated value quicker and easier.
    func unwrap() -> StreamSink {
        if case let StreamSinkProvider.provider(unwrapped) = self {
            return unwrapped
        }
        fatalError() //this should never happen since only one case
    }
}
