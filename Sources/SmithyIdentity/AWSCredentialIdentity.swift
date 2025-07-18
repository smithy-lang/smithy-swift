//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import protocol SmithyIdentityAPI.Identity
import struct Foundation.Date
import struct Smithy.Attributes

/// A type representing AWS credentials for authenticating with an AWS service
///
/// For more information see [AWS security credentials](https://docs.aws.amazon.com/general/latest/gr/aws-security-credentials.html#AccessKeys)
public struct AWSCredentialIdentity: Identity {
    public let accessKey: String
    public let secret: String
    public let accountID: String?
    public let sessionToken: String?
    public let expiration: Date?
    public let properties: Attributes

    /// Creates AWS credentials with the specified keys and optionally an expiration and session token.
    ///
    /// - Parameters:
    ///   - accessKey: The access key
    ///   - secret: The secret for the provided access key
    ///   - accountID: The account ID for the credentials, if known.  Defaults to `nil`.
    ///   - expiration: The date when the credentials will expire and no longer be valid. If value is `nil` then the credentials never expire. Defaults to `nil`
    ///   - sessionToken: A session token for this session. Defaults to `nil`
    ///   - properties: Arbitrary grab-bag of properties related to this credentials object.
    public init(
        accessKey: String,
        secret: String,
        accountID: String? = nil,
        expiration: Date? = nil,
        sessionToken: String? = nil,
        properties: Attributes = Attributes()
    ) {
        self.accessKey = accessKey
        self.secret = secret
        self.accountID = accountID
        self.expiration = expiration
        self.sessionToken = sessionToken
        self.properties = properties
    }
}
