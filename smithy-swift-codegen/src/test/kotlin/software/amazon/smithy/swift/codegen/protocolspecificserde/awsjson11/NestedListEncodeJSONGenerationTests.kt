package software.amazon.smithy.swift.codegen.protocolspecificserde.awsjson11

/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test
import software.amazon.smithy.swift.codegen.TestContext
import software.amazon.smithy.swift.codegen.defaultSettings
import software.amazon.smithy.swift.codegen.getFileContents
import software.amazon.smithy.swift.codegen.protocolgeneratormocks.MockHTTPAWSJson11ProtocolGenerator
import software.amazon.smithy.swift.codegen.shouldSyntacticSanityCheck

class NestedListEncodeJSONGenerationTests {
    @Test
    fun `list of maps of lists`() {
        val context = setupTests("Isolated/json11/lists-of-maps-of-lists.smithy", "aws.protocoltests.json#JsonProtocol")
        val contents = getFileContents(context.manifest, "Sources/Example/models/ListOfMapsOperationInput.swift")
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
public struct ListOfMapsOperationInput: Swift.Sendable {
    public var targetMaps: [[Swift.String: [Swift.String]]]?

    public init(
        targetMaps: [[Swift.String: [Swift.String]]]? = nil
    ) {
        self.targetMaps = targetMaps
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `encode list of maps of lists`() {
        val context = setupTests("Isolated/json11/lists-of-maps-of-lists.smithy", "aws.protocoltests.json#JsonProtocol")
        val contents = getFileContents(context.manifest, "Sources/Example/models/ListOfMapsOperationInput+Write.swift")
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
extension ListOfMapsOperationInput {

    static func write(value: ListOfMapsOperationInput?, to writer: SmithyJSON.Writer) throws {
        guard let value else { return }
        try writer["targetMaps"].writeList(value.targetMaps, memberWritingClosure: SmithyReadWrite.mapWritingClosure(valueWritingClosure: SmithyReadWrite.listWritingClosure(memberWritingClosure: SmithyReadWrite.WritingClosures.writeString(value:to:), memberNodeInfo: "member", isFlattened: false), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false), memberNodeInfo: "member", isFlattened: false)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    private fun setupTests(
        smithyFile: String,
        serviceShapeId: String,
    ): TestContext {
        val context =
            TestContext.initContextFrom(smithyFile, serviceShapeId, MockHTTPAWSJson11ProtocolGenerator()) { model ->
                model.defaultSettings(serviceShapeId, "Example", "2014-11-06", "aws json 11")
            }
        context.generator.generateCodableConformanceForNestedTypes(context.generationCtx)
        context.generator.generateSerializers(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
