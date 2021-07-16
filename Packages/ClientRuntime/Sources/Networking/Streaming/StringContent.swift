//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import AwsCommonRuntimeKit

extension String {
    func toByteBuffer() -> ByteBuffer {
        return ByteBuffer(data: self.data(using: .utf8) ?? Data())
    }
}
