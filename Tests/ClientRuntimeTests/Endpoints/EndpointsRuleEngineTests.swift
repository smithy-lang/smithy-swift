//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import ClientRuntime
import XCTest

class EndpointsRuleEngineTests: XCTestCase {
    func test_resolve() async throws {
        guard let path = Bundle.module.path(forResource: "endpoint_rules", ofType: "json") else {
            fatalError("endpoint_rules.json not found")
        }

        guard let jsonString = try? String(contentsOfFile: path, encoding: .utf8) else {
            fatalError("Unable to convert endpoint_rules.json to String")
        }

        let endpointsRuleEngine = try EndpointsRuleEngine(ruleSet: jsonString)
        let context = try EndpointsRequestContext()
        try context.add(name: "Stage", value: "gamma")
        let resolvedEndpoint = try endpointsRuleEngine.resolve(context: context)
        XCTAssertEqual("https://service.com/gamma", resolvedEndpoint?.getURL())
    }
}
