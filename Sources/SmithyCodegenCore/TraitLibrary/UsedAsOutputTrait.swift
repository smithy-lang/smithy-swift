//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import enum Smithy.Node
import struct Smithy.ShapeID
import protocol Smithy.Trait

public struct UsedAsOutputTrait: Trait {
    public static var id: ShapeID { .init("swift.synthetic", "usedAsOutput") }

    public var node: Node { [:] }

    public init(node: Node) throws {}

    public init() {}
}
