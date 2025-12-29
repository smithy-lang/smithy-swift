//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SmithyHTTPAuthAPI

public class AuthSchemePlugin: Plugin {

    private var authSchemes: [AuthScheme]?

    private var authSchemeResolver: AuthSchemeResolver?

    public init(
        authSchemeResolver: AuthSchemeResolver? = nil,
        authSchemes: [AuthScheme]? = nil
    ) {
        self.authSchemeResolver = authSchemeResolver
        self.authSchemes = authSchemes
    }

    public func configureClient(clientConfiguration: ClientConfiguration) async throws -> ClientConfiguration {
        // Since configurations are now immutable structs, we can't mutate them.
        // The auth schemes and resolver are already set in the configuration's initializer,
        // so this plugin doesn't need to do anything.
        return clientConfiguration
    }
}
