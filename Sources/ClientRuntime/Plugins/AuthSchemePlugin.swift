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

    public func configureClient(clientConfiguration: ClientConfiguration) {
        if var config = clientConfiguration as? DefaultHttpClientConfiguration {
            if self.authSchemes != nil {
                config.authSchemes = self.authSchemes!
            }
            if self.authSchemeResolver != nil {
                config.authSchemeResolver = self.authSchemeResolver!
            }
        }
    }
}
