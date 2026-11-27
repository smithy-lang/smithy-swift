//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// https://smithy.io/2.0/aws/customizations/s3-customizations.html#aws-customizations-s3unwrappedxmloutput-trait
///
/// Marks an S3 operation whose response body is not wrapped in the operation's output element: the root
/// element of the body is the output's single member.  It is applied at runtime by S3's client plugin.
@_spi(SchemaBasedSerde)
public final class S3UnwrappedXMLOutputTrait: RuntimeTrait {
    public static var id: ShapeID { .init("aws.customizations", "s3UnwrappedXmlOutput") }

    public static let uniqueIndex = traitUniqueIndexCounter.getNextIndex()

    public var node: Node { [:] }

    public init(node: Node) throws {}
}
