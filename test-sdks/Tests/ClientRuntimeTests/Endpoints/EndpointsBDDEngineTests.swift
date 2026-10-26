//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import ClientRuntime
import Foundation
import XCTest

class EndpointsBDDEngineTests: XCTestCase {

    /// Compiled from endpoint_bdd.json. Static, like generated code, because the BDD engine reads it in place.
    static let bytecode: Data = {
        guard let url = Bundle.module.url(forResource: "endpoint_bdd", withExtension: "bin"),
              let data = try? Data(contentsOf: url) else {
            fatalError("endpoint_bdd.bin not found")
        }
        return data
    }()

    struct Params: EndpointsRequestContextProviding {
        let region: String
        let useFips: Bool

        var context: EndpointsRequestContext {
            get throws {
                let context = try EndpointsRequestContext()
                try context.add(name: "Region", value: region)
                try context.add(name: "UseFips", value: useFips)
                return context
            }
        }
    }

    func test_engine_resolve() throws {
        let engine = try EndpointsBDDEngine(bytecode: Self.bytecode)
        let context = try EndpointsRequestContext()
        try context.add(name: "Region", value: "us-west-2")
        let resolvedEndpoint = try engine.resolve(context: context)
        XCTAssertEqual("https://service.us-west-2.amazonaws.com", resolvedEndpoint?.getURL())
        XCTAssertEqual(["*", "us-west-2"], resolvedEndpoint?.getHeaders()?["x-amz-multi"])
    }

    func test_defaultEndpointResolver_resolvesWithBytecode() throws {
        let resolver = try DefaultEndpointResolver<Params>(partitions: partitionJSON, bytecode: Self.bytecode)
        let endpoint = try resolver.resolve(params: Params(region: "us-west-2", useFips: false))
        XCTAssertEqual("service.us-west-2.amazonaws.com", endpoint.uri.host)
        XCTAssertEqual(["us-west-2"], endpoint.headers.values(for: "x-amz-region"))
        XCTAssertEqual(["*", "us-west-2"], endpoint.headers.values(for: "x-amz-multi"))
    }

    func test_defaultEndpointResolver_followsBDDBranch() throws {
        let resolver = try DefaultEndpointResolver<Params>(partitions: partitionJSON, bytecode: Self.bytecode)
        let endpoint = try resolver.resolve(params: Params(region: "us-west-2", useFips: true))
        XCTAssertEqual("service-fips.us-west-2.amazonaws.com", endpoint.uri.host)
    }
}
