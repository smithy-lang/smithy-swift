//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import protocol SmithyIdentityAPI.IdentityResolver

public protocol BearerTokenIdentityResolver: IdentityResolver where IdentityT == BearerTokenIdentity {}
