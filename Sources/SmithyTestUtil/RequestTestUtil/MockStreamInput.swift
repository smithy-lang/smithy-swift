//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import enum SmithyStreamsAPI.ByteStream

public struct MockStreamInput {
    let body: ByteStream

    public init(body: ByteStream) {
        self.body = body
    }
}
