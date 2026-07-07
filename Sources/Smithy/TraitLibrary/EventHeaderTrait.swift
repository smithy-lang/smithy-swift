//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// https://smithy.io/2.0/spec/streaming.html#eventheader-trait
@_spi(SchemaBasedSerde)
public final class EventHeaderTrait: RuntimeTrait {
    public static var id: ShapeID { .init("smithy.api", "eventHeader") }

    public static let uniqueIndex = traitUniqueIndexCounter.getNextIndex()

    public var node: Node { [:] }

    public init(node: Node) throws {}

    public init() {}
}
