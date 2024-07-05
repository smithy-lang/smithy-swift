//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct SmithyHTTPAPI.Endpoint

public struct StaticEndpointResolver<Params: EndpointsRequestContextProviding> {

    private let endpoint: SmithyHTTPAPI.Endpoint

    public init(endpoint: SmithyHTTPAPI.Endpoint) {
        self.endpoint = endpoint
    }

    public func resolve(params: Params) throws -> SmithyHTTPAPI.Endpoint {
        return endpoint
    }
}
