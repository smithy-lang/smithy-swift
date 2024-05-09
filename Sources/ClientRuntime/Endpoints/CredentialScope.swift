//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct CredentialScope {
    public let region: String?
    public let serviceId: String?

    public init(region: String? = nil, serviceId: String? = nil) {
        self.region = region
        self.serviceId = serviceId
    }
}
