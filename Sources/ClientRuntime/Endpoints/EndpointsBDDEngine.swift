//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import AwsCommonRuntimeKit
import struct Foundation.Data

/// Wrapper for CRTAWSEndpointsBDDEngine
public final class EndpointsBDDEngine: @unchecked Sendable {

    let crtEngine: AwsCommonRuntimeKit.EndpointsBDDEngine

    public init(partitions: String = partitionJSON, bytecode: Data) throws {
        CommonRuntimeKit.initialize()  // ensures CRT is set up before calling the CRT endpoint BDD engine
        crtEngine = try AwsCommonRuntimeKit.EndpointsBDDEngine(partitions: partitions, bytecode: bytecode)
    }

    public func resolve(context: EndpointsRequestContext) throws -> CRTResolvedEndpoint? {
        let crtResolvedEndpoint = try crtEngine.resolve(context: context.toCRT())
        return CRTResolvedEndpoint(crtResolvedEndpoint: crtResolvedEndpoint)
    }
}
