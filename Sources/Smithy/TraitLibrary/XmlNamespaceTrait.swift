//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct XmlNamespaceTrait: Trait {
    public static var id: ShapeID { .init("smithy.api", "xmlNamespace") }
    public let uri: String
    public let prefix: String?
    public var node: Node {
        var dict: [String: Node] = ["uri": .string(uri)]
        if let prefix { dict["prefix"] = .string(prefix) }
        return .object(dict)
    }

    public init(node: Node) throws {
        guard case .object(let dict) = node else {
            throw TraitError("xmlNamespace trait requires an object value")
        }
        guard case .string(let uri) = dict["uri"] else {
            throw TraitError("xmlNamespace trait requires a 'uri' string")
        }
        self.uri = uri
        if case .string(let prefix) = dict["prefix"] {
            self.prefix = prefix
        } else {
            self.prefix = nil
        }
    }
}
