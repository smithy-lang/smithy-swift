//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import struct SmithyHTTPAPI.Endpoint
import enum SmithyHTTPAPI.EndpointPropertyValue
import struct SmithyHTTPAPI.Headers

/// An engine that can resolve endpoints (rule set or BDD)
protocol EndpointsEngine: Sendable {
    func resolve(context: EndpointsRequestContext) throws -> CRTResolvedEndpoint?
}

extension EndpointsRuleEngine: EndpointsEngine {}
extension EndpointsBDDEngine: EndpointsEngine {}

public struct DefaultEndpointResolver<Params: EndpointsRequestContextProviding>: Sendable {

    private let engine: any EndpointsEngine

    public init(partitions: String, ruleSet: String) throws {
        engine = try ClientRuntime.EndpointsRuleEngine(partitions: partitions, ruleSet: ruleSet)
    }

    public init(partitions: String, bytecode: Data) throws {
        engine = try ClientRuntime.EndpointsBDDEngine(partitions: partitions, bytecode: bytecode)
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
        return try Endpoint(urlString: url, headers: Headers(headers), endpointProperties: properties)
    }
}
