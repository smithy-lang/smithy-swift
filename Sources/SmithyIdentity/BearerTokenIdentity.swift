//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import protocol SmithyIdentityAPI.Identity
import struct Foundation.Date

public struct BearerTokenIdentity: Identity {
    public let token: String
    public let expiration: Date?
}
