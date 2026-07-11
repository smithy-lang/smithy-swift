//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// https://smithy.io/2.0/spec/http-bindings.html#httpquery-trait

@_spi(SchemaBasedSerde)
public final class HTTPQueryTrait: RuntimeTrait {
    public static var id = ShapeID("smithy.api", "httpQuery")

    public static let uniqueIndex = traitUniqueIndexCounter.getNextIndex()

    public var node: Node { .string(name) }
    public let name: String

    public init(node: Node) throws {
        guard let name = node.string else { throw TraitError("httpQuery trait node must contain String") }
        self.name = name
    }
}
