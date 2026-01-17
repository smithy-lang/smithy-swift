//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct OutputTrait: Trait {
    public static var id: ShapeID { .init("smithy.api", "output") }

    public var node: Node { [:] }

    public init(node: Node) throws {}

    public init() {}
}
