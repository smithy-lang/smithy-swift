//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct TargetsUnitTrait: Trait {
    public static var id: ShapeID { .init("swift.synthetic", "targetsUnit") }

    public var node: Node { [:] }

    public init(node: Node) throws {}

    public init () {}
}
