//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Smithy.AttributeKey
import class Smithy.Context
import class Smithy.ContextBuilder

@_spi(SchemaBasedSerde)
public extension Context {

    func getOperationProperties() -> (any OperationProperties)? {
        get(key: operationPropertiesKey)
    }
}

@_spi(SchemaBasedSerde)
public extension ContextBuilder {

    func withOperationProperties(value: any OperationProperties) -> Self {
        attributes.set(key: operationPropertiesKey, value: value)
        return self
    }
}

private let operationPropertiesKey = AttributeKey<any OperationProperties>(name: "OperationProperties")
