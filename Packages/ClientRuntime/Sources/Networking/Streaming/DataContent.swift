//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import AwsCommonRuntimeKit
	
public struct DataContent: Buffer {
    public var contentLength: Int64? {
        return Int64(data.count)
    }
    
    public func toBytes() -> ByteBuffer {
        return ByteBuffer(data: data)
    }
    
    private let data: Data
    
    public init(data: Data) {
        self.data = data
    }
}

extension Data {
    public func asByteStream() -> ByteStream {
        return .buffer(DataContent(data: self))
    }
}
