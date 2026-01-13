//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class SmithyHTTPAPI.HTTPRequest
import class SmithyHTTPAPI.HTTPResponse
import protocol SmithySerialization.ClientProtocol
import struct SmithySerialization.Operation

public protocol HTTPConfigurating {
    associatedtype RequestType = HTTPRequest
    associatedtype ResponseType = HTTPResponse

    func configure<InputType, OutputType>(
        _ operation: Operation<InputType, OutputType>,
        _ builder: OrchestratorBuilder<InputType, OutputType, HTTPRequest, HTTPResponse>
    )
}
