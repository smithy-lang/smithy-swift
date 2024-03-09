//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public class AuthSchemePlugin: Plugin {

    private var authSchemes: [ClientRuntime.AuthScheme]?

    private var authSchemeResolver: ClientRuntime.AuthSchemeResolver?

    public init(
        authSchemeResolver: ClientRuntime.AuthSchemeResolver? = nil,
        authSchemes: [ClientRuntime.AuthScheme]? = nil
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
