//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import enum Smithy.Node
import struct Smithy.ShapeID
import protocol Smithy.Trait

public struct UsedAsInputTrait: Trait {
    public static var id: ShapeID { .init("swift.synthetic", "usedAsInput") }

    public var node: Node { [:] }

    public init(node: Node) throws {}

    public init() {}
}
