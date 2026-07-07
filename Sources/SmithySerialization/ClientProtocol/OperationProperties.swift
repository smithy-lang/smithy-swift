//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(SchemaBasedSerde)
import class Smithy.Schema

@_spi(SchemaBasedSerde)
public protocol OperationProperties: Sendable {
    var schema: Schema { get }
    var serviceSchema: Schema { get }
    var inputSchema: Schema { get }
    var outputSchema: Schema { get }
    var errorTypeRegistry: TypeRegistry { get }
}
