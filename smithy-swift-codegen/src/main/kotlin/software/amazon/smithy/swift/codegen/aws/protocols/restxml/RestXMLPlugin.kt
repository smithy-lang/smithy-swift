package software.amazon.smithy.swift.codegen.aws.protocols.restxml

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.integration.Plugin
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyRestXMLTypes

class RestXMLPlugin : Plugin {
    override val className: Symbol = SmithyRestXMLTypes.Plugin
}
