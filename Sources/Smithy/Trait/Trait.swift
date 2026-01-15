//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public protocol Trait {
    static var id: ShapeID { get }

    var node: Node { get }

    init(node: Node) throws
}

public extension Trait {

    var id: ShapeID { Self.id }
}
