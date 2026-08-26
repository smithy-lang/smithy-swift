//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// https://smithy.io/2.0/spec/http-bindings.html#httpprefixheaders-trait

@_spi(SchemaBasedSerde)
public final class HTTPPrefixHeadersTrait: RuntimeTrait {
    public static let id = ShapeID("smithy.api", "httpPrefixHeaders")

    public static let uniqueIndex = traitUniqueIndexCounter.getNextIndex()

    public var node: Node { .string(prefix) }

    /// The string prepended to each map key to form a header name.  May be empty.
    public let prefix: String

    public init(node: Node) throws {
        guard let prefix = node.string else {
            throw TraitError("httpPrefixHeaders trait node must contain String")
        }
        self.prefix = prefix
    }
}
