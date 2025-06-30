//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct SigningFlags: Sendable {
    public let useDoubleURIEncode: Bool
    public let shouldNormalizeURIPath: Bool
    public let omitSessionToken: Bool

    public init(useDoubleURIEncode: Bool, shouldNormalizeURIPath: Bool, omitSessionToken: Bool) {
        self.useDoubleURIEncode = useDoubleURIEncode
        self.shouldNormalizeURIPath = shouldNormalizeURIPath
        self.omitSessionToken = omitSessionToken
    }
}
