//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public protocol Signer {
    func sign<IdentityT: Identity>(
        requestBuilder: SdkHttpRequestBuilder,
        identity: IdentityT,
        signingProperties: Attributes
    ) async throws -> SdkHttpRequestBuilder
}
