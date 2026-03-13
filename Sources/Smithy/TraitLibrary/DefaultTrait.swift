//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// https://smithy.io/2.0/spec/type-refinement-traits.html#default-trait
public struct DefaultTrait: Trait {
    public static var id: ShapeID { .init("smithy.api", "default") }

    public let node: Node

    public init(node: Node) throws {
        self.node = node
    }

    public init(_ bool: Bool) {
        self.node = .boolean(bool)
    }

    public init(_ integer: Int) {
        self.node = .number(Double(integer))
    }

    public init(_ double: Double) {
        self.node = .number(double)
    }
}
