//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Smithy
import SmithyHTTPAPI
import SmithyReadWrite
import ClientRuntime

public struct MockDeserializeMiddleware<OperationStackOutput> {
    public var id: String
    let responseClosure: WireResponseOutputClosure<HttpResponse, OperationStackOutput>

    public init(id: String, responseClosure: @escaping WireResponseOutputClosure<HttpResponse, OperationStackOutput>) {
        self.id = id
        self.responseClosure = responseClosure
    }
}

extension MockDeserializeMiddleware: ResponseMessageDeserializer {
    public func deserialize(response: HttpResponse, attributes: Context) async throws -> OperationStackOutput {
        return try await responseClosure(response)
    }
}
