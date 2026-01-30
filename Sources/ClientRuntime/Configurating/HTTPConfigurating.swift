//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class Smithy.ContextBuilder
import class SmithyHTTPAPI.HTTPRequest
import class SmithyHTTPAPI.HTTPResponse
import protocol SmithySerialization.ClientProtocol
import struct SmithySerialization.Operation

public protocol HTTPConfigurating {
    associatedtype RequestType = HTTPRequest
    associatedtype ResponseType = HTTPResponse
    associatedtype ClientProtocol: SmithySerialization.ClientProtocol

    var clientProtocol: ClientProtocol { get }

    func configure<InputType, OutputType>(
        _ operation: Operation<InputType, OutputType>,
        _ context: ContextBuilder,
        _ orchestrator: OrchestratorBuilder<InputType, OutputType, HTTPRequest, HTTPResponse>
    )
}
