//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCommonRuntimeKit

/// Wrapper for CRTAWSEndpointsRuleEngine
public class EndpointsRuleEngine {

    let crtEngine: AwsCommonRuntimeKit.EndpointsRuleEngine

    public init(partitions: String = partitionJSON, ruleSet: String) throws {
        CommonRuntimeKit.initialize()  // ensures CRT is set up before calling the CRT endpoint rules engine
        crtEngine = try AwsCommonRuntimeKit.EndpointsRuleEngine(partitions: partitions, ruleSet: ruleSet)
    }

    public func resolve(context: EndpointsRequestContext) throws -> CRTResolvedEndpoint? {
        let crtResolvedEndpoint = try crtEngine.resolve(context: context.toCRT())
        return CRTResolvedEndpoint(crtResolvedEndpoint: crtResolvedEndpoint)
    }
}
