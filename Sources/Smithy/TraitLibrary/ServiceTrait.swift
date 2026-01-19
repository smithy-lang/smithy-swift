//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct ServiceTrait: Trait {
    public static var id: ShapeID { .init("aws.api", "service") }

    public let node: Node
    public let sdkId: String

    public init(node: Node) throws {
        guard case .object(let object) = node else {
            throw TraitError("ServiceTrait does not have root object")
        }
        guard let sdkId = object["sdkId"]?.string else {
            throw TraitError("ServiceTrait does not have sdkId")
        }
        self.node = node
        self.sdkId = sdkId
    }
}
