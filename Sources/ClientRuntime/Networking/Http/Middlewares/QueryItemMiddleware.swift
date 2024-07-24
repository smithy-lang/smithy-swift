//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import protocol Smithy.RequestMessageSerializer
import class Smithy.Context
import SmithyHTTPAPI

public struct QueryItemMiddleware<OperationStackInput, OperationStackOutput> {
    public let id: String = "\(String(describing: OperationStackInput.self))QueryItemMiddleware"

    let queryItemProvider: QueryItemProvider<OperationStackInput>

    public init(_ queryItemProvider: @escaping QueryItemProvider<OperationStackInput>) {
        self.queryItemProvider = queryItemProvider
    }
}

extension QueryItemMiddleware: RequestMessageSerializer {
    public typealias InputType = OperationStackInput
    public typealias RequestType = HTTPRequest

    public func apply(input: OperationStackInput, builder: HTTPRequestBuilder, attributes: Smithy.Context) throws {
        for queryItem in try queryItemProvider(input) {
            builder.withQueryItem(queryItem)
        }
    }
}
