package TestSupport.Mocks

import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.HttpProtocolCustomizable
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator

class MockHttpProtocolCustomizations : HttpProtocolCustomizable() {
    override fun renderMiddlewares(ctx: ProtocolGenerator.GenerationContext, writer: SwiftWriter, op: OperationShape, operationStackName: String) {
    }
    override fun renderContextAttributes(ctx: ProtocolGenerator.GenerationContext, writer: SwiftWriter, op: OperationShape) {
    }
}
