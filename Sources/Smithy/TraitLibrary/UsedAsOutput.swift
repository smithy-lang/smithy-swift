//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct UsedAsOutputTrait: Trait {
    public static var id: ShapeID { .init("swift.synthetic", "usedAsOutput") }

    public var node: Node { [:] }

    public init(node: Node) throws {}

    public init() {}
}
