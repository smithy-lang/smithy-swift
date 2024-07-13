//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import protocol Smithy.RequestMessageSerializer
import class Smithy.Context
import enum Smithy.ByteStream
import class SmithyHTTPAPI.SdkHttpRequest
import class SmithyHTTPAPI.SdkHttpRequestBuilder
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
    public typealias RequestType = SdkHttpRequest

    public func apply(input: OperationStackInput, builder: SdkHttpRequestBuilder, attributes: Smithy.Context) throws {
        if let byteStream = input[keyPath: keyPath] {
            builder.withBody(byteStream)
        }
    }
}
