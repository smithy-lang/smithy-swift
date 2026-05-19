//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import ClientRuntime

// RestXML URL paths come from per-operation @http traits, so no protocol-level
// interceptor wiring is needed here.
@_spi(SchemaBasedSerde)
public struct Plugin: ClientRuntime.Plugin {

    public init() {}

    public func configureClient<Config: ClientConfiguration>(clientConfiguration: inout Config) async throws {
    }
}
