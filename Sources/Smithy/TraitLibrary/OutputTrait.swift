//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// https://smithy.io/2.0/spec/type-refinement-traits.html#smithy-api-output-trait
public struct OutputTrait: Trait {
    public static var id: ShapeID { .init("smithy.api", "output") }

    public var node: Node { [:] }

    public init(node: Node) throws {}

    public init() {}
}
