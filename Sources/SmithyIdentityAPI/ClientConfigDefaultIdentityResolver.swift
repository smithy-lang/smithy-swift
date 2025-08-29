//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// A protocol on identity resolver used to signify that this resolver is a default resolver created because the client config was not passed a custom resolver at creation.
///
/// Resolvers that do not implement this protocol should be presumed to not be a client config default.

@_spi(ClientConfigDefaultIdentityResolver)
public protocol ClientConfigDefaultIdentityResolver: IdentityResolver {

    /// Indicates whether this identity resolver was provided as a client config default.
    var isClientConfigDefault: Bool { get }
}
