//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Smithy.Schema

public struct Operation<Input: SerializableStruct, Output: DeserializableStruct> {
    private let _schema: @Sendable () -> Schema
    private let _serviceSchema: @Sendable () -> Schema
    private let _inputSchema: @Sendable () -> Schema
    private let _outputSchema: @Sendable () -> Schema
    private let _errorTypeRegistry: @Sendable () -> TypeRegistry

    public init(
        schema: @autoclosure @escaping @Sendable () -> Schema,
        serviceSchema: @autoclosure @escaping @Sendable () -> Schema,
        inputSchema: @autoclosure @escaping @Sendable () -> Schema,
        outputSchema: @autoclosure @escaping @Sendable () -> Schema,
        errorTypeRegistry: @autoclosure @escaping @Sendable () -> TypeRegistry
    ) {
        self._schema = schema
        self._serviceSchema = serviceSchema
        self._inputSchema = inputSchema
        self._outputSchema = outputSchema
        self._errorTypeRegistry = errorTypeRegistry
    }
}

extension Operation: OperationProperties {

    public var schema: Schema { _schema() }

    public var serviceSchema: Schema { _serviceSchema() }

    public var inputSchema: Schema { _inputSchema() }

    public var outputSchema: Schema { _outputSchema() }

    public var errorTypeRegistry: TypeRegistry { _errorTypeRegistry() }
}
