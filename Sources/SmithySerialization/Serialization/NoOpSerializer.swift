//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// An implementation of `ShapeSerializer` that is no-op for every method.
@_spi(SchemaBasedSerde)
public final class NoOpSerializer: NoOpByDefaultShapeSerializer {

    public init() {}

    public var mediaType: String? { nil }
}
