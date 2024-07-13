//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import protocol Smithy.RequestMessageSerializer
import class Smithy.Context
import class SmithyHTTPAPI.SdkHttpRequest
import class SmithyHTTPAPI.SdkHttpRequestBuilder
import struct Foundation.Data

public struct BlobBodyMiddleware<OperationStackInput, OperationStackOutput> {
    public let id: Swift.String = "BlobBodyMiddleware"

    let keyPath: KeyPath<OperationStackInput, Data?>

    public init(keyPath: KeyPath<OperationStackInput, Data?>) {
        self.keyPath = keyPath
    }
}

extension BlobBodyMiddleware: RequestMessageSerializer {
    public typealias InputType = OperationStackInput
    public typealias RequestType = SdkHttpRequest

    public func apply(input: OperationStackInput, builder: SdkHttpRequestBuilder, attributes: Smithy.Context) throws {
        builder.withBody(.data(input[keyPath: keyPath]))
    }
}
