//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public protocol AuthSchemeResolver {
    func resolveAuthScheme(params: AuthSchemeResolverParameters) -> [AuthOption]
    func constructParameters(context: HttpContext) throws -> AuthSchemeResolverParameters
}
