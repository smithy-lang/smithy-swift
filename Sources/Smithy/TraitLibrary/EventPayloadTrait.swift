//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// https://smithy.io/2.0/spec/streaming.html#eventpayload-trait

public struct EventPayloadTrait: Trait {
    public static var id: ShapeID { .init("smithy.api", "eventPayload") }

    public var node: Node { [:] }

    public init(node: Node) throws {}

    public init() {}
}
