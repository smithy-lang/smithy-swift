/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
package software.amazon.smithy.swift.codegen.aws.protocols

import software.amazon.smithy.swift.codegen.aws.protocols.awsjson.AWSJSON1_0ProtocolGenerator
import software.amazon.smithy.swift.codegen.aws.protocols.awsjson.AWSJSON1_1ProtocolGenerator
import software.amazon.smithy.swift.codegen.aws.protocols.awsquery.AWSQueryProtocolGenerator
import software.amazon.smithy.swift.codegen.aws.protocols.ec2query.EC2QueryProtocolGenerator
import software.amazon.smithy.swift.codegen.aws.protocols.restjson.RestJson1ProtocolGenerator
import software.amazon.smithy.swift.codegen.aws.protocols.restxml.RestXmlProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.SwiftIntegration
import software.amazon.smithy.swift.codegen.protocols.rpcv2cbor.RpcV2CborProtocolGenerator

/**
 * Registers protocol generators with default customizations.
 *
 * Downstream modules (e.g. aws-sdk-swift) may override these by registering
 * generators with the same protocol ShapeId at a higher order.
 */
class AddAWSProtocols : SwiftIntegration {
    override val order: Byte = -20

    override val protocolGenerators: List<ProtocolGenerator> =
        listOf(
            RpcV2CborProtocolGenerator(),
            RestJson1ProtocolGenerator(),
            AWSJSON1_0ProtocolGenerator(),
            AWSJSON1_1ProtocolGenerator(),
            RestXmlProtocolGenerator(),
            AWSQueryProtocolGenerator(),
            EC2QueryProtocolGenerator(),
        )
}
