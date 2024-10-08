//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import enum Smithy.ByteStream

public struct MockStreamInput {
    public let body: ByteStream

    public init(body: ByteStream) {
        self.body = body
    }
}
