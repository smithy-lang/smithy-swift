//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct HttpResponseCodeTrait: Trait {
    public static var id: ShapeID { .init("smithy.api", "httpResponseCode") }
    public var node: Node { [:] }
    public init(node: Node) throws {}
}
