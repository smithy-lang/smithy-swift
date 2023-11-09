//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public protocol AuthSchemeResolver {
    associatedtype Parameters: AuthSchemeResolverParameters

    func resolveAuthScheme(params: Parameters) throws -> [AuthOption]
    func constructParameters(context: HttpContext) throws -> Parameters
}
