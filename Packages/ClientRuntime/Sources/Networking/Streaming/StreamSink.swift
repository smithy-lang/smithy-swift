/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import AwsCommonRuntimeKit
import class Foundation.FileHandle
import class Foundation.FileManager

// TODO: handle backpressure more thoroughly to allow for indication that they are ready for more
@available(*, message: "This streaming interface is unstable currently for dynamic streaming")
public protocol StreamSink: AnyObject {
    var availableForRead: Int { get set }
    var isClosedForWrite: Bool {get set}

    ///Read up to limit of bytes into a ByteBuffer until limit is reached or channel is closed.
    ///WARNING:  Be careful as this will potentially read the entire byte stream into memory (up to limit).
    func readRemaining(limit: Int) -> ByteBuffer
    func readFully(sink: ByteBuffer)
    func onError(error: ClientError)
}

//public class DataStreamSink: StreamSink {
//    public var contentLength: Int? {
//        return data.count
//    }
//
//    public func toBytes() -> ByteBuffer {
//        return ByteBuffer(data: data)
//    }
//
//    public var data: Data
//    public var error: ClientError?
//
//    init(data: Data = Data()) {
//        self.data = data
//    }
//
//    public func receiveData(readFrom buffer: ByteBuffer) {
//        data.append(buffer.toData())
//    }
//
//    public func onError(error: ClientError) {
//        self.error = error
//    }
//}
//
//public class FileStreamSink: StreamSink {
//    public var contentLength: Int? {
//        return Int(fileHandle?.length ?? 0)
//    }
//
//    public func toBytes() -> ByteBuffer {
//        return ByteBuffer(data: fileHandle?.availableData ?? Data())
//    }
//
//
//    public var fileHandle: FileHandle?
//    public var error: ClientError?
//
//    init(filePath: String) {
//
//        let fileManager = FileManager.default
//        fileManager.createFile(atPath: filePath, contents: nil)
//        self.fileHandle = FileHandle(forWritingAtPath: filePath)
//    }
//
//    public func receiveData(readFrom buffer: ByteBuffer) {
//        fileHandle?.write(buffer.toData())
//    }
//
//    public func onError(error: ClientError) {
//        self.error = error
//    }
//}
//
//public enum StreamSinkProvider {
//    case provider(StreamSink)
//}
//
//extension StreamSinkProvider {
//    public static func defaultDataProvider() -> StreamSinkProvider {
//        return .provider(DataStreamSink())
//    }
//
//    public static func defaultFileProvider(filePath: String) -> StreamSinkProvider {
//        return .provider(FileStreamSink(filePath: filePath))
//    }
//
//    public func toData() -> Data? {
//        let dataStream = self.unwrap() as? DataStreamSink
//        return dataStream?.data
//    }
//
//    public func toFile() -> FileHandle? {
//        let fileStream = self.unwrap() as? FileStreamSink
//        return fileStream?.fileHandle
//    }
//
//    /// This function is a util to enhance developer experience. This enum only has one case so this function
//    /// provides an easy way to unwrap the single case to get the associated value quicker and easier.
//    public func unwrap() -> StreamSink {
//        if case let StreamSinkProvider.provider(unwrapped) = self {
//            return unwrapped
//        }
//        fatalError() // this should never happen since only one case
//    }
//}
