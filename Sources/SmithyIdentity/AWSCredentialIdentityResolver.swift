//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class AwsCommonRuntimeKit.CredentialsProvider
import struct Smithy.Attributes
import protocol SmithyIdentityAPI.IdentityResolver

/// A type that can provide credentials for authenticating with an AWS service
public protocol AWSCredentialIdentityResolver: IdentityResolver, Sendable where IdentityT == AWSCredentialIdentity {}

public extension AWSCredentialIdentityResolver {

    /// Returns the underlying `AwsCommonRuntimeKit.CredentialsProvider`.
    /// If `self` is not backed by a `AwsCommonRuntimeKit.CredentialsProvider` then this wraps `self`
    /// in a `CustomAWSCredentialIdentityResolver` which will create a `AwsCommonRuntimeKit.CredentialsProvider`.
    func getCRTAWSCredentialIdentityResolver() throws -> AwsCommonRuntimeKit.CredentialsProvider {
        let providerSourcedByCRT = try self as? (any AWSCredentialIdentityResolvedByCRT)
        ?? CustomAWSCredentialIdentityResolver(self)
        return providerSourcedByCRT.crtAWSCredentialIdentityResolver
    }

    func getIdentity(identityProperties: Attributes? = nil) async throws -> AWSCredentialIdentity {
        let crtAWSCredentialIdentity = try await self.getCRTAWSCredentialIdentityResolver().getCredentials()
        return try .init(crtAWSCredentialIdentity: crtAWSCredentialIdentity)
    }
}
