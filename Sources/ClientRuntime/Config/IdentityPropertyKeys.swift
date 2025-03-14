//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Smithy.AttributeKey

public enum IdentityPropertyKeys {

    /// The service client config to be used in credential resolution.
    ///
    /// Used only in conjunction with the `awsv4-s3express` auth scheme, which generates bucket-specific credentials
    /// for use with the S3 Express service.
    public static let clientConfig = AttributeKey<any DefaultClientConfiguration>(name: "ClientRuntimeClientConfig")
}
