//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import ClientRuntime
import Smithy
import class SmithyHTTPAPI.HTTPRequest
import class SmithyHTTPAPI.HTTPResponse
import protocol SmithySerialization.DeserializableStruct
import protocol SmithySerialization.SerializableStruct

public struct Plugin: ClientRuntime.Plugin {

    public init() {}

    public func configureClient<Config: ClientConfiguration>(clientConfiguration: inout Config) async throws {
        // RestXML plugin currently has no additional configuration to apply.
        // URL path and other HTTP bindings are handled by code-generated middlewares.
    }
}
