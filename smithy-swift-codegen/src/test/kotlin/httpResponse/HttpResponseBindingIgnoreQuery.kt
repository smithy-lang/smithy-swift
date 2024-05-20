/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package httpResponse

import MockHTTPRestJsonProtocolGenerator
import TestContext
import defaultSettings
import getFileContents
import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test
import shouldSyntacticSanityCheck

class HttpResponseBindingIgnoreQuery {

    @Test
    fun `001 Output httpResponseBinding ignores query trait & decodes field`() {
        val context = setupTests("http-query-payload.smithy", "aws.protocoltests.restjson#RestJson")
        val contents = getFileContents(context.manifest, "/RestJson/models/IgnoreQueryParamsInResponseOutput+HttpResponseBinding.swift")
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
extension IgnoreQueryParamsInResponseOutput {

    static func httpOutput(from httpResponse: ClientRuntime.HttpResponse) async throws -> IgnoreQueryParamsInResponseOutput {
        let data = try await httpResponse.data()
        let responseReader = try SmithyJSON.Reader.from(data: data)
        let reader = responseReader
        var value = IgnoreQueryParamsInResponseOutput()
        value.baz = try reader["baz"].readIfPresent()
        return value
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
        val context = TestContext.initContextFrom(smithyFile, serviceShapeId, MockHTTPRestJsonProtocolGenerator()) { model ->
            model.defaultSettings(serviceShapeId, "RestJson", "2019-12-16", "Rest Json Protocol")
        }
        context.generator.generateDeserializers(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
