//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct SmithyHTTPAPI.Endpoint
import struct SmithyHTTPAPI.Headers

public struct DefaultEndpointResolver<Params: EndpointsRequestContextProviding>  {

    private let engine: ClientRuntime.EndpointsRuleEngine

    public init(partitions: String, ruleSet: String) throws {
        engine = try ClientRuntime.EndpointsRuleEngine(partitions: partitions, ruleSet: ruleSet)
    }

    public func resolve(params: Params) throws -> SmithyHTTPAPI.Endpoint {
        guard let crtResolvedEndpoint = try engine.resolve(context: params.context) else {
            throw EndpointError.unresolved("Failed to resolved endpoint")
        }

        if crtResolvedEndpoint.getType() == .error {
            let error = crtResolvedEndpoint.getError()
            throw EndpointError.unresolved(error)
        }

        guard let url = crtResolvedEndpoint.getURL() else {
            assertionFailure("This must be a bug in either CRT or the rule engine, if the endpoint is not an error, it must have a url")
            throw EndpointError.unresolved("Failed to resolved endpoint")
        }

        let headers = crtResolvedEndpoint.getHeaders() ?? [:]
        let properties = crtResolvedEndpoint.getProperties() ?? [:]
        return try Endpoint(urlString: url, headers: Headers(headers), properties: properties)
    }
}
