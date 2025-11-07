//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import class Smithy.Context
import protocol Smithy.RequestMessageSerializer
import class SmithyHTTPAPI.HTTPRequest
import class SmithyHTTPAPI.HTTPRequestBuilder

public struct BlobBodyMiddleware<OperationStackInput, OperationStackOutput> {
    public let id: Swift.String = "BlobBodyMiddleware"

    let keyPath: KeyPath<OperationStackInput, Data?>

    public init(keyPath: KeyPath<OperationStackInput, Data?>) {
        self.keyPath = keyPath
    }
}

extension BlobBodyMiddleware: RequestMessageSerializer {
    public typealias InputType = OperationStackInput
    public typealias RequestType = HTTPRequest

    public func apply(input: OperationStackInput, builder: HTTPRequestBuilder, attributes: Smithy.Context) throws {
        builder.withBody(.data(input[keyPath: keyPath]))
    }
}
