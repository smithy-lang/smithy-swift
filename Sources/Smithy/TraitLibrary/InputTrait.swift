//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct InputTrait: Trait {
    public static var id: ShapeID { .init("smithy.api", "input") }

    public var node: Node { [:] }

    public init(node: Node) throws {}

    public init() {}
}
