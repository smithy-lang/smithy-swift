//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct SmithyRetries.DefaultRetryStrategy

public class DefaultClientPlugin: Plugin {
    public init() {}
    public func configureClient(clientConfiguration: ClientConfiguration) async throws -> ClientConfiguration {
        // Since configurations are now immutable structs, we can't mutate them.
        // The defaults are already set in the configuration's initializer,
        // so this plugin doesn't need to do anything.
        return clientConfiguration
    }
}
