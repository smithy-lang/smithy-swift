package serde.awsjson11

import TestContext
import defaultSettings
import getFileContents
import io.kotest.matchers.string.shouldContainOnlyOnce
import mocks.MockHttpAWSJson11ProtocolGenerator
import org.junit.jupiter.api.Test
import shouldSyntacticSanityCheck

class NestedListEncodeJSONGenerationTests {

    @Test
    fun `list of maps of lists`() {
        val context = setupTests("Isolated/json11/lists-of-maps-of-lists.smithy", "aws.protocoltests.json#JsonProtocol")
        val contents = getFileContents(context.manifest, "/Example/models/ListOfMapsOperationInput.swift")
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            public struct ListOfMapsOperationInput: Swift.Equatable {
                public var targetMaps: [[Swift.String:[Swift.String]]]?
            
                public init(
                    targetMaps: [[Swift.String:[Swift.String]]]? = nil
                )
                {
                    self.targetMaps = targetMaps
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `encode list of maps of lists`() {
        val context = setupTests("Isolated/json11/lists-of-maps-of-lists.smithy", "aws.protocoltests.json#JsonProtocol")
        val contents = getFileContents(context.manifest, "/Example/models/ListOfMapsOperationInput+Write.swift")
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
extension ListOfMapsOperationInput {

    static func write(value: ListOfMapsOperationInput?, to writer: SmithyJSON.Writer) throws {
        guard let value else { return }
        try writer["targetMaps"].writeList(value.targetMaps, memberWritingClosure: mapWritingClosure(valueWritingClosure: listWritingClosure(memberWritingClosure: Swift.String.write(value:to:), memberNodeInfo: "member", isFlattened: false), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false), memberNodeInfo: "member", isFlattened: false)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }
    private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
        val context = TestContext.initContextFrom(smithyFile, serviceShapeId, MockHttpAWSJson11ProtocolGenerator()) { model ->
            model.defaultSettings(serviceShapeId, "Example", "2014-11-06", "aws json 11")
        }
        context.generator.generateCodableConformanceForNestedTypes(context.generationCtx)
        context.generator.generateSerializers(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
