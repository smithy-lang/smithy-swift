//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import protocol SmithyIdentityAPI.Identity
import struct Foundation.Date
import struct Smithy.Attributes

/// The type representing bearer token identity, used in HTTP bearer auth.
public struct BearerTokenIdentity: Identity {
    public let token: String
    public let expiration: Date?
    public let properties: Attributes

    public init(token: String, expiration: Date? = nil, properties: Attributes = Attributes()) {
        self.token = token
        self.expiration = expiration
        self.properties = properties
    }
}
