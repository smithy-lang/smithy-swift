//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct AddedDefaultTrait: Trait {
    public static var id: ShapeID { .init("smithy.api", "addedDefault") }

    public var node: Node { [:] }

    public init(node: Node) throws {}
}
