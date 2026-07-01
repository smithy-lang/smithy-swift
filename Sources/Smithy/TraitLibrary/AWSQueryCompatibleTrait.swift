//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// https://smithy.io/2.0/aws/protocols/aws-query-protocol.html#aws-protocols-awsquerycompatible-trait
@_spi(SchemaBasedSerde)
public struct AWSQueryCompatibleTrait: Trait {
    public static var id: ShapeID { .init("aws.protocols", "awsQueryCompatible") }

    public static let uniqueIndex = TraitRegistry.shared.register(Self.self)

    public var node: Node { [:] }

    public init(node: Node) throws {}
}
