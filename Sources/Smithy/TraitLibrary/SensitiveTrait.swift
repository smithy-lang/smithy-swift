//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// https://smithy.io/2.0/spec/documentation-traits.html#smithy-api-sensitive-trait
@_spi(SchemaBasedSerde)
public final class SensitiveTrait: RuntimeTrait {
    public static var id: ShapeID { .init("smithy.api", "sensitive") }

    public static let uniqueIndex = traitUniqueIndexCounter.getNextIndex()

    public var node: Node { [:] }

    public init(node: Node) throws {}

    public init() {}
}
