//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import ClientRuntime

public struct MockAuthSchemeResolverParameters: ClientRuntime.AuthSchemeResolverParameters {
    public let operation: String
}

public protocol MockAuthSchemeResolver: ClientRuntime.AuthSchemeResolver {
    // Intentionally empty.
    // This is the parent protocol that all auth scheme resolver implementations of
    // the service Mock must conform to.
}

public struct DefaultMockAuthSchemeResolver: MockAuthSchemeResolver {
    public init () {}

    public func resolveAuthScheme(params: ClientRuntime.AuthSchemeResolverParameters) throws -> [AuthOption] {
        var validAuthOptions = Array<AuthOption>()
        guard let serviceParams = params as? MockAuthSchemeResolverParameters else {
            throw ClientError.authError("Service specific auth scheme parameters type must be passed to auth scheme resolver.")
        }
        switch serviceParams.operation {
            case "authA":
                validAuthOptions.append(AuthOption(schemeID: "MockAuthSchemeA"))
            case "authAB":
                validAuthOptions.append(AuthOption(schemeID: "MockAuthSchemeA"))
                validAuthOptions.append(AuthOption(schemeID: "MockAuthSchemeB"))
            case "authABC":
                validAuthOptions.append(AuthOption(schemeID: "MockAuthSchemeA"))
                validAuthOptions.append(AuthOption(schemeID: "MockAuthSchemeB"))
                validAuthOptions.append(AuthOption(schemeID: "MockAuthSchemeC"))
            case "authABCNoAuth":
                validAuthOptions.append(AuthOption(schemeID: "MockAuthSchemeA"))
                validAuthOptions.append(AuthOption(schemeID: "MockAuthSchemeB"))
                validAuthOptions.append(AuthOption(schemeID: "MockAuthSchemeC"))
                validAuthOptions.append(AuthOption(schemeID: "smithy.api#noAuth"))
            default:
                validAuthOptions.append(AuthOption(schemeID: "fillerAuth"))
        }
        return validAuthOptions
    }

    public func constructParameters(context: HttpContext) throws -> ClientRuntime.AuthSchemeResolverParameters {
        guard let opName = context.getOperation() else {
            throw ClientError.dataNotFound("Operation name not configured in middleware context for auth scheme resolver params construction.")
        }
        return MockAuthSchemeResolverParameters(operation: opName)
    }
}
