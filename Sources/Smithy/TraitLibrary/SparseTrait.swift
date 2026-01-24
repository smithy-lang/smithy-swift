//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// https://smithy.io/2.0/spec/type-refinement-traits.html#sparse-trait
public struct SparseTrait: Trait {
    public static var id: ShapeID { .init("smithy.api", "sparse") }

    public var node: Node { [:] }

    public init(node: Node) throws {}
}
