//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import protocol Smithy.RequestMessageSerializer
import class Smithy.Context
import enum Smithy.ByteStream
import class SmithyHTTPAPI.HTTPRequest
import class SmithyHTTPAPI.HTTPRequestBuilder
import struct Foundation.Data

public struct BlobStreamBodyMiddleware<OperationStackInput, OperationStackOutput> {
    public let id: Swift.String = "BlobStreamBodyMiddleware"

    let keyPath: KeyPath<OperationStackInput, ByteStream?>

    public init(keyPath: KeyPath<OperationStackInput, ByteStream?>) {
        self.keyPath = keyPath
    }
}

extension BlobStreamBodyMiddleware: RequestMessageSerializer {
    public typealias InputType = OperationStackInput
    public typealias RequestType = HTTPRequest

    public func apply(input: OperationStackInput, builder: HTTPRequestBuilder, attributes: Smithy.Context) throws {
        if let byteStream = input[keyPath: keyPath] {
            builder.withBody(byteStream)
        }
    }
}
