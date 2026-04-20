//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct HttpPayloadTrait: Trait {
    public static var id: ShapeID { .init("smithy.api", "httpPayload") }
    public var node: Node { [:] }
    public init(node: Node) throws {}
}
