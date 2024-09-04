//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Smithy
import SmithyHTTPAPI
@_spi(SmithyReadWrite) import SmithyReadWrite
import ClientRuntime

@_spi(SmithyReadWrite)
public struct MockDeserializeMiddleware<OperationStackOutput> {
    public var id: String
    let responseClosure: WireResponseOutputClosure<HTTPResponse, OperationStackOutput>

    public init(id: String, responseClosure: @escaping WireResponseOutputClosure<HTTPResponse, OperationStackOutput>) {
        self.id = id
        self.responseClosure = responseClosure
    }
}

extension MockDeserializeMiddleware: ResponseMessageDeserializer {
    public func deserialize(response: HTTPResponse, attributes: Context) async throws -> OperationStackOutput {
        return try await responseClosure(response)
    }
}
