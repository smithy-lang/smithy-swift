package software.amazon.smithy.swift.codegen.protocolspecificserde.xml

/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import software.amazon.smithy.swift.codegen.TestContext
import software.amazon.smithy.swift.codegen.defaultSettings
import software.amazon.smithy.swift.codegen.protocolgeneratormocks.MockHTTPRestXMLProtocolGenerator

fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
    val context = TestContext.initContextFrom(smithyFile, serviceShapeId, MockHTTPRestXMLProtocolGenerator()) { model ->
        model.defaultSettings(serviceShapeId, "RestXml", "2019-12-16", "Rest Xml Protocol")
    }
    context.generator.initializeMiddleware(context.generationCtx)
    context.generator.generateSerializers(context.generationCtx)
    context.generator.generateCodableConformanceForNestedTypes(context.generationCtx)
    context.generator.generateDeserializers(context.generationCtx)
    context.generator.generateProtocolClient(context.generationCtx)
    context.generationCtx.delegator.flushWriters()
    return context
}