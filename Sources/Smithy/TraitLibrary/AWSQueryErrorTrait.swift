//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct AWSQueryErrorTrait: Trait {
    public static var id: ShapeID { .init("aws.protocols", "awsQueryError") }

    public let node: Node
    public let code: String
    public let httpResponseCode: Int

    public init(node: Node) throws {
        guard case .object(let object) = node else {
            throw TraitError("AWSQueryError trait does not have root object")
        }
        guard case .string(let code) = object["code"] else {
            throw TraitError("AWSQueryError trait does not have code")
        }
        guard case .number(let httpResponseCode) = object["httpResponseCode"] else {
            throw TraitError("AWSQueryError trait does not have httpResponseCode")
        }
        self.node = node
        self.code = code
        self.httpResponseCode = Int(httpResponseCode)
    }
}
