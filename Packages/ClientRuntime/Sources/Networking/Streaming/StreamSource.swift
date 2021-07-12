/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import AwsCommonRuntimeKit
import struct Foundation.Data
import class Foundation.FileManager
import struct Foundation.URL

@available(*, message: "This streaming interface is unstable currently for dynamic streaming")
public protocol StreamSource {
    @discardableResult
    mutating func sendData(writeTo buffer: ByteBuffer) -> Bool
    mutating func onError(error: ClientError)
}

class DataStreamSource: StreamSource {
    var contentLength: Int?
    
    public func toBytes() -> ByteBuffer {
        return ByteBuffer(data: data)
    }
    
    let data: Data
    var error: ClientError?

    init(data: Data) {
        self.data = data
        self.contentLength = data.count
    }
    
    public func sendData(writeTo buffer: ByteBuffer) -> Bool {
        buffer.put(data)
        return true
    }
    
    public func onError(error: ClientError) {
        self.error = error
    }
}

class FileStreamSource: StreamSource {

    let filePath: String
    var error: ClientError?
    var contentLength: Int?
    let data: Data?
    
    init(filePath: String) {
        self.filePath = filePath
        let fileManager = FileManager.default
        self.data = fileManager.contents(atPath: filePath)
        self.contentLength = data?.count
    }
    
    func toBytes() -> ByteBuffer {
        return ByteBuffer(data: data ?? Data())
    }
    
    public func sendData(writeTo buffer: ByteBuffer) -> Bool {
        if let data = data {
        buffer.put(data)
        return true
        } else {
            return false
        }
    }
    
    public func onError(error: ClientError) {
        self.error = error
    }
}

public enum StreamSourceProvider {
    case provider(StreamSource)
}

extension StreamSourceProvider {
    public static func from(data: Data) -> StreamSourceProvider {
        return .provider(DataStreamSource(data: data))
    }
    
    public static func from(filePath: String) -> StreamSourceProvider {
        return .provider(FileStreamSource(filePath: filePath))
    }
    
    /// This function is a util to enhance developer experience. This enum only has one case so this function
    /// provides an easy way to unwrap the single case to get the associated value quicker and easier.
    public func unwrap() -> StreamSource {
        if case let StreamSourceProvider.provider(unwrapped) = self {
            return unwrapped
        }
        fatalError() // this should never happen since only one case
    }
}

