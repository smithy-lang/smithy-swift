//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// https://smithy.io/2.0/spec/http-bindings.html#httpresponsecode-trait
@_spi(SchemaBasedSerde)
public final class HTTPResponseCodeTrait: RuntimeTrait {
    public static var id: ShapeID { .init("smithy.api", "httpResponseCode") }

    public static let uniqueIndex = traitUniqueIndexCounter.getNextIndex()

    public var node: Node { [:] }

    public init(node: Node) throws {}

    public init() {}
}
