//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(SchemaBasedSerde)
public protocol SchemaExtension: UniquelyIndexedByType {}

@_spi(SchemaBasedSerde)
public let schemaExtensionUniqueIndexCounter = UniqueIndexCounter()
