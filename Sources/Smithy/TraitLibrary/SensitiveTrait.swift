//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct SensitiveTrait: Trait {
    public static var id: ShapeID { .init("smithy.api", "sensitive") }

    public var node: Node { [:] }

    public init(node: Node) throws {}
}
