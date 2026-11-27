package software.amazon.smithy.swift.codegen.aws.protocols.ec2query

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.integration.Plugin
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyEC2QueryTypes

class EC2QueryPlugin : Plugin {
    override val className: Symbol = SmithyEC2QueryTypes.Plugin
}
