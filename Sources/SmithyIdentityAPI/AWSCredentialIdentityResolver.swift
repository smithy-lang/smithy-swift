//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// A type that can provide credentials for authenticating with an AWS service
public protocol AWSCredentialIdentityResolver: IdentityResolver where IdentityT == AWSCredentialIdentity {}
