//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(SchemaBasedSerde)
public struct HttpQueryTrait: Trait {
    public static var id: ShapeID { .init("smithy.api", "httpQuery") }
    public let value: String
    public var node: Node { .string(value) }

    public init(node: Node) throws {
        guard case .string(let value) = node else {
            throw TraitError("httpQuery trait requires a string value")
        }
        self.value = value
    }
}
