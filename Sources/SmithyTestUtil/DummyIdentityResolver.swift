//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct SmithyIdentity.StaticAWSCredentialIdentityResolver

public func dummyIdentityResolver() throws -> StaticAWSCredentialIdentityResolver {
    StaticAWSCredentialIdentityResolver(
        .init(
            accessKey: "dummy-aws-access-key-id",
            secret: "dummy-aws-secret-access-key"
        )
    )
}
