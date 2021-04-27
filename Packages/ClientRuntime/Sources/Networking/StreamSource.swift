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
    var contentLength: Int64 {get set}
    @discardableResult
    func sendData(writeTo buffer: ByteBuffer) -> Bool
    mutating func onError(error: StreamError)
}

struct DataStreamSource: StreamSource {
    let data: Data
    var error: StreamError?
    var contentLength: Int64
    init(data: Data) {
        self.data = data
        self.contentLength = Int64(data.count)
    }
    
    public func sendData(writeTo buffer: ByteBuffer) -> Bool {
        buffer.put(data)
        return true
    }
    
    public mutating func onError(error: StreamError) {
        self.error = error
    }
}

struct FileStreamSource: StreamSource {
    let filePath: String
    var error: StreamError?
    var contentLength: Int64
    let data: Data?
    
    init(filePath: String) {
        self.filePath = filePath
        let fileManager = FileManager.default
        self.data = fileManager.contents(atPath: filePath)
        self.contentLength = Int64(data?.count ?? 0)
    }
    
    public func sendData(writeTo buffer: ByteBuffer) -> Bool {
        if let data = data {
        buffer.put(data)
        return true
        } else {
            return false
        }
    }
    
    public mutating func onError(error: StreamError) {
        self.error = error
    }
}

public enum StreamSourceProvider {
    case provider(StreamSource)
}

extension StreamSourceProvider {
    public static func fromData(data: Data) -> StreamSourceProvider {
        return .provider(DataStreamSource(data: data))
    }
    
    public static func fromFile(filePath: String) -> StreamSourceProvider {
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
