//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct SmithyHTTPAPI.Endpoint
import struct SmithyHTTPAPI.Headers

public struct DefaultEndpointResolver<Params: EndpointsRequestContextProviding> {

    private let engine: ClientRuntime.EndpointsRuleEngine

    public init(partitions: String, ruleSet: String) throws {
        engine = try ClientRuntime.EndpointsRuleEngine(partitions: partitions, ruleSet: ruleSet)
    }

    public func resolve(params: Params) throws -> SmithyHTTPAPI.Endpoint {
        guard let crtResolvedEndpoint = try engine.resolve(context: params.context) else {
            throw EndpointError.unresolved("Failed to resolve endpoint")
        }

        if crtResolvedEndpoint.getType() == .error {
            let error = crtResolvedEndpoint.getError()
            throw EndpointError.unresolved(error)
        }

        guard let url = crtResolvedEndpoint.getURL() else {
            throw EndpointError.unresolved("Failed to get URL from endpoint")
        }

        let headers = crtResolvedEndpoint.getHeaders() ?? [:]
        let properties = crtResolvedEndpoint.getProperties() ?? [:]
        return try Endpoint(urlString: url, headers: Headers(headers), properties: properties)
    }
}
