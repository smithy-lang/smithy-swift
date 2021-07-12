//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import AwsCommonRuntimeKit
	
public struct StringContent: Buffer {
    public var contentLength: Int? {
        return string.count
    }
    
    public func toBytes() -> ByteBuffer {
        return ByteBuffer(data: string.data(using: .utf8) ?? Data())
    }
    private let string: String
    public init(string: String) {
        self.string = string
    }
}

extension String {
    public func asByteStream() -> ByteStream {
        return .buffer(StringContent(string: self))
    }
}
