//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class Smithy.Context
import protocol Smithy.RequestMessageSerializer
import struct Foundation.Data
import SmithyHTTPAPI

public struct EnumBodyMiddleware<OperationStackInput,
                                 OperationStackOutput,
                                 Primitive: RawRepresentable> where Primitive.RawValue == String {
    public let id: Swift.String = "EnumBodyMiddleware"

    let keyPath: KeyPath<OperationStackInput, Primitive?>

    public init(keyPath: KeyPath<OperationStackInput, Primitive?>) {
        self.keyPath = keyPath
    }
}

extension EnumBodyMiddleware: RequestMessageSerializer {
    public typealias InputType = OperationStackInput
    public typealias RequestType = HTTPRequest

    public func apply(input: OperationStackInput, builder: HTTPRequestBuilder, attributes: Smithy.Context) throws {
        let bodyString = input[keyPath: keyPath]?.rawValue ?? ""
        let bodyData = Data(bodyString.utf8)
        builder.withBody(.data(bodyData))
    }
}
