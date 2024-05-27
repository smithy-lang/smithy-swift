//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class Smithy.Context

public protocol AuthSchemeResolver {
    func resolveAuthScheme(params: AuthSchemeResolverParameters) throws -> [AuthOption]
    func constructParameters(context: Context) throws -> AuthSchemeResolverParameters
}
