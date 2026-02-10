//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Smithy.AttributeKey
import class Smithy.Context
import class Smithy.ContextBuilder
import protocol SmithySerialization.ClientProtocol
import struct SmithySerialization.Operation

extension Context {

    func operation<Input, Output>() -> Operation<Input, Output>? {
        get(key: operationContextKey) as? Operation<Input, Output>
    }

    var clientProtocol: (any ClientProtocol)? {
        `get`(key: clientProtocolKey)
    }
}

extension ContextBuilder {

    func withOperation<Input, Output>(_ operation: SmithySerialization.Operation<Input, Output>) -> ContextBuilder {
        attributes.set(key: operationContextKey, value: operation)
        return self
    }

    func withClientProtocol(_ clientProtocol: any ClientProtocol) -> ContextBuilder {
        attributes.set(key: clientProtocolKey, value: clientProtocol)
        return self
    }
}

private let operationContextKey = AttributeKey<Any>(name: "OperationContextKey")
private let clientProtocolKey = AttributeKey<any ClientProtocol>(name: "ClientProtocolKey")
