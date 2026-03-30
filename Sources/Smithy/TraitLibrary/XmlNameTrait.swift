//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct XmlNameTrait: Trait {
    public static var id: ShapeID { .init("smithy.api", "xmlName") }
    public let value: String
    public var node: Node { .string(value) }

    public init(node: Node) throws {
        guard case .string(let value) = node else {
            throw TraitError("xmlName trait requires a string value")
        }
        self.value = value
    }
}
