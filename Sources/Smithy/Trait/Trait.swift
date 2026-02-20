//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// An interface for working with Smithy traits stored in a ``TraitCollection``.
///
/// All traits have a ``Node`` associated with them, but will typically provide their properties
/// with convenient, type-safe accessors.
public protocol Trait {
    static var id: ShapeID { get }

    var node: Node { get }

    init(node: Node) throws
}

public extension Trait {

    var id: ShapeID { Self.id }
}
