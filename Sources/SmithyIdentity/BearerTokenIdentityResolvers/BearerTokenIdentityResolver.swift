//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import protocol SmithyIdentityAPI.IdentityResolver

/// The type that resolves a bearer token identity for authenticating with a service.
/// All concrete implementations for bearer token identity resolver must conform to this protocol.
public protocol BearerTokenIdentityResolver: IdentityResolver where IdentityT == BearerTokenIdentity {}
