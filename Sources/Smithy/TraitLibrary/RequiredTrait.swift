//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct RequiredTrait: Trait {
    public static var id: ShapeID { .init("smithy.api", "required") }

    public var node: Node { [:] }

    public init(node: Node) throws {}

    public init() {}
}
