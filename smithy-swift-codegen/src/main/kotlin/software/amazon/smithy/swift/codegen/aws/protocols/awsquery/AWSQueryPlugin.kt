package software.amazon.smithy.swift.codegen.aws.protocols.awsquery

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.integration.Plugin
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyAWSQueryTypes

class AWSQueryPlugin : Plugin {
    override val className: Symbol = SmithyAWSQueryTypes.Plugin
}
