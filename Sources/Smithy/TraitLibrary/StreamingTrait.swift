//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// https://smithy.io/2.0/spec/streaming.html#smithy-api-streaming-trait
@_spi(SchemaBasedSerde)
public final class StreamingTrait: RuntimeTrait {
    public static var id: ShapeID { .init("smithy.api", "streaming") }

    public static let uniqueIndex = traitUniqueIndexCounter.getNextIndex()

    public var node: Node { [:] }

    public init(node: Node) throws {}

    public init() {}
}
