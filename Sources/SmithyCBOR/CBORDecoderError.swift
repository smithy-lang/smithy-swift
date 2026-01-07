//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct CBORDecoderError: Error {
    public let localizedDescription: String

    public init(_ localizedDescription: String) {
        self.localizedDescription = localizedDescription
    }
}

struct DecodedNull: Error {}
