//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// A schema extension is an object that contains data which a serializer or deserializer wishes to
/// reuse when processing the same schema in the future.
///
/// Schema extensions are stored on the schema itself the first time a schema is accessed, and
/// retrieved from the schema during subsequent accesses.
@_spi(SchemaBasedSerde)
public protocol SchemaExtension: AnyObject, UniquelyIndexedByType {}

/// Call `getNextIndex()` on this counter to generate a unique index for each type of schema extension.
@_spi(SchemaBasedSerde)
public let schemaExtensionUniqueIndexCounter = UniqueIndexCounter()
