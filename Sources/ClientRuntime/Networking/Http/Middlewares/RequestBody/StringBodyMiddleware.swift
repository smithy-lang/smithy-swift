//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import protocol Smithy.RequestMessageSerializer
import class Smithy.Context
import struct Foundation.Data
import SmithyHTTPAPI

public struct StringBodyMiddleware<OperationStackInput, OperationStackOutput> {
    public let id: Swift.String = "\(OperationStackInput.self)StringBodyMiddleware"

    let keyPath: KeyPath<OperationStackInput, String?>

    public init(keyPath: KeyPath<OperationStackInput, String?>) {
        self.keyPath = keyPath
    }
}

extension StringBodyMiddleware: RequestMessageSerializer {
    public typealias InputType = OperationStackInput
    public typealias RequestType = HTTPRequest

    public func apply(input: OperationStackInput, builder: HTTPRequestBuilder, attributes: Smithy.Context) throws {
        builder.withBody(.data(Data((input[keyPath: keyPath] ?? "").utf8)))
    }
}
