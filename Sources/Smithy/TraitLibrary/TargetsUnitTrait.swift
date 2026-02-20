//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// A synthetic trait that is used to identify operation inputs & outputs that were either left
/// undefined or that targeted `smithy.api#Unit`.
///
/// This trait is applied using a model transform, prior to code generation.
public struct TargetsUnitTrait: Trait {
    public static var id: ShapeID { .init("swift.synthetic", "targetsUnit") }

    public var node: Node { [:] }

    public init(node: Node) throws {}

    public init () {}
}
