package software.amazon.smithy.swift.codegen.integration.serde.readwrite

import software.amazon.smithy.aws.traits.protocols.AwsJson1_0Trait
import software.amazon.smithy.aws.traits.protocols.AwsJson1_1Trait
import software.amazon.smithy.aws.traits.protocols.AwsQueryTrait
import software.amazon.smithy.aws.traits.protocols.Ec2QueryTrait
import software.amazon.smithy.aws.traits.protocols.RestJson1Trait
import software.amazon.smithy.aws.traits.protocols.RestXmlTrait
import software.amazon.smithy.model.shapes.ServiceShape
import software.amazon.smithy.swift.codegen.model.hasTrait

// An enum expressing the six defined AWS protocols used with Smithy.
enum class AWSProtocol {
    REST_XML, AWS_QUERY, EC2_QUERY, REST_JSON_1, AWS_JSON_1_0, AWS_JSON_1_1
}

// The AWS protocols that may be used with Smithy.
val ServiceShape.awsProtocol: AWSProtocol
    get() = when {
        hasTrait<RestXmlTrait>() -> AWSProtocol.REST_XML
        hasTrait<AwsQueryTrait>() -> AWSProtocol.AWS_QUERY
        hasTrait<Ec2QueryTrait>() -> AWSProtocol.EC2_QUERY
        hasTrait<RestJson1Trait>() -> AWSProtocol.REST_JSON_1
        hasTrait<AwsJson1_0Trait>() -> AWSProtocol.AWS_JSON_1_0
        hasTrait<AwsJson1_1Trait>() -> AWSProtocol.AWS_JSON_1_1
        else -> throw Exception("Service does not use a supported protocol")
    }

// The wire protocols that an AWS protocol may use over the wire for its requests or responses.
enum class WireProtocol {
    XML, FORM_URL, JSON
}

// The wire protocol used for this service's requests.
val ServiceShape.requestWireProtocol: WireProtocol
    get() = when (awsProtocol) {
        AWSProtocol.AWS_QUERY, AWSProtocol.EC2_QUERY -> WireProtocol.FORM_URL
        AWSProtocol.REST_XML -> WireProtocol.XML
        AWSProtocol.REST_JSON_1, AWSProtocol.AWS_JSON_1_0, AWSProtocol.AWS_JSON_1_1 -> WireProtocol.JSON
    }

// The wire protocol used for this service's responses.
val ServiceShape.responseWireProtocol: WireProtocol
    get() = when (awsProtocol) {
        AWSProtocol.REST_XML, AWSProtocol.AWS_QUERY, AWSProtocol.EC2_QUERY -> WireProtocol.XML
        AWSProtocol.REST_JSON_1, AWSProtocol.AWS_JSON_1_0, AWSProtocol.AWS_JSON_1_1 -> WireProtocol.JSON
    }

// Whether this AWS protocol is RPC.
val ServiceShape.isRPCBound: Boolean
    get() = when (awsProtocol) {
        AWSProtocol.AWS_JSON_1_0, AWSProtocol.AWS_JSON_1_1, AWSProtocol.AWS_QUERY, AWSProtocol.EC2_QUERY -> true
        else -> false
    }
