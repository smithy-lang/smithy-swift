package software.amazon.smithy.swift.codegen.protocols.rpcv2cbor

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.integration.Plugin
import software.amazon.smithy.swift.codegen.swiftmodules.RPCv2CBORTypes

class RPCv2CBORPlugin : Plugin {
    override val className: Symbol = RPCv2CBORTypes.Plugin
}
