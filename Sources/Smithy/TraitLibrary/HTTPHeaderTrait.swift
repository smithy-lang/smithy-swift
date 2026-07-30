//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// https://smithy.io/2.0/spec/http-bindings.html#httpheader-trait

@_spi(SchemaBasedSerde)
public final class HTTPHeaderTrait: RuntimeTrait {
    public static let id = ShapeID("smithy.api", "httpHeader")

    public static let uniqueIndex = traitUniqueIndexCounter.getNextIndex()

    public var node: Node { .string(name) }
    public let name: String

    public init(node: Node) throws {
        guard let name = node.string else { throw TraitError("httpHeader trait node must contain String") }
        self.name = name
    }
}
