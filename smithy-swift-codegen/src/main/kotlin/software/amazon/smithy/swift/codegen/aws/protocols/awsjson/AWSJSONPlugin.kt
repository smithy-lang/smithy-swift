package software.amazon.smithy.swift.codegen.aws.protocols.awsjson

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.integration.Plugin
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyAWSJSONTypes

class AWSJSONPlugin : Plugin {
    override val className: Symbol = SmithyAWSJSONTypes.Plugin
}
