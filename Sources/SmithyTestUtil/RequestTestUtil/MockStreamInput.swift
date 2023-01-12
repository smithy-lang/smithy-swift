//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import ClientRuntime

public struct MockStreamInput: Encodable {
    let body: ByteStream

    public init(body: ByteStream) {
        self.body = body
    }
}
