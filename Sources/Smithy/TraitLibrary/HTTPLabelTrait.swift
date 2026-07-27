//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// https://smithy.io/2.0/spec/http-bindings.html#httplabel-trait

@_spi(SchemaBasedSerde)
public final class HTTPLabelTrait: RuntimeTrait {
    public static let id = ShapeID("smithy.api", "httpLabel")

    public static let uniqueIndex = traitUniqueIndexCounter.getNextIndex()

    public var node: Node { [:] }

    public required init(node: Node) throws {}
}
