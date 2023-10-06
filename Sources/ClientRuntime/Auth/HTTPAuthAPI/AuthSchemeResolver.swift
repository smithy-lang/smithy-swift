//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public protocol AuthSchemeResolver {
    func resolveAuthScheme(params: AuthSchemeResolverParameters) -> Array<AuthOption>
    func constructParameters(context: HttpContext) throws -> AuthSchemeResolverParameters
}
