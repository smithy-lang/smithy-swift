//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import AwsCommonRuntimeKit
	
public struct StringContent {
    public var contentLength: Int64? {
        return Int64(underlyingStringBuffer.count)
    }
    
    public func toBytes() -> ByteBuffer {
        return ByteBuffer(data: underlyingStringBuffer.data(using: .utf8) ?? Data())
    }
    private let underlyingStringBuffer: String
    public init(underlyingStringBuffer: String) {
        self.underlyingStringBuffer = underlyingStringBuffer
    }
}
