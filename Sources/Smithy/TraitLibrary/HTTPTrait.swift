//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// https://smithy.io/2.0/spec/http-bindings.html#http-trait

@_spi(SchemaBasedSerde)
public final class HTTPTrait: RuntimeTrait {
    public static let id = ShapeID("smithy.api", "http")

    public static let uniqueIndex = traitUniqueIndexCounter.getNextIndex()

    public let method: String
    public let uri: String

    public var node: Node { [
        "method": .string(method),
        "uri": .string(uri),
    ] }

    public required init(node: Node) throws {
        guard let object = node.object else { throw TraitError("http trait does not have object at root") }
        guard let method = object["method"]?.string else { throw TraitError("http trait does not have method") }
        guard let uri = object["uri"]?.string else { throw TraitError("http trait does not have uri") }
        self.method = method
        self.uri = uri
    }
}
