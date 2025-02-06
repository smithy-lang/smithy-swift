//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SmithyHTTPAuthAPI

public class AuthSchemePlugin<Config: DefaultHttpClientConfiguration>: Plugin {

    private var authSchemes: [AuthScheme]?

    private var authSchemeResolver: AuthSchemeResolver?

    public init(
        authSchemeResolver: AuthSchemeResolver? = nil,
        authSchemes: [AuthScheme]? = nil
    ) {
        self.authSchemeResolver = authSchemeResolver
        self.authSchemes = authSchemes
    }

    public func configureClient(clientConfiguration: Config) -> Config {
        var copy = clientConfiguration
        if self.authSchemes != nil {
            copy.authSchemes = self.authSchemes!
        }
        if self.authSchemeResolver != nil {
            copy.authSchemeResolver = self.authSchemeResolver!
        }
        return copy
    }
}
