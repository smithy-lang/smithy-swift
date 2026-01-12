//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class Smithy.Schema

public struct Operation<Input: SerializableStruct, Output: DeserializableStruct> {
    private let _schema: () -> Schema
    private let _serviceSchema: () -> Schema
    private let _inputSchema: () -> Schema
    private let _outputSchema: () -> Schema
    private let _errorTypeRegistry: () -> TypeRegistry

    public init(
        schema: @autoclosure @escaping () -> Schema,
        serviceSchema: @autoclosure @escaping () -> Schema,
        inputSchema: @autoclosure @escaping () -> Schema,
        outputSchema: @autoclosure @escaping () -> Schema,
        errorTypeRegistry: @autoclosure @escaping () -> TypeRegistry
    ) {
        self._schema = schema
        self._serviceSchema = serviceSchema
        self._inputSchema = inputSchema
        self._outputSchema = outputSchema
        self._errorTypeRegistry = errorTypeRegistry
    }

    public var schema: Schema { _schema() }

    public var serviceSchema: Schema { _serviceSchema() }

    public var inputSchema: Schema { _inputSchema() }

    public var outputSchema: Schema { _outputSchema() }

    public var errorTypeRegistry: TypeRegistry { _errorTypeRegistry() }
}
