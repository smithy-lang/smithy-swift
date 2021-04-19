package serde.xml

import MockHttpRestXMLProtocolGenerator
import TestContext
import defaultSettings
import getFileContents
import io.kotest.matchers.string.shouldContainOnlyOnce
import listFilesFromManifest
import org.junit.jupiter.api.Test

class UnionEncodeXMLGenerationTests {
    @Test
    fun `001 unions`() {
        val context = setupTests("Isolated/Restxml/xml-unions.smithy", "aws.protocoltests.restxml#RestXml")
        print(listFilesFromManifest(context.manifest))
        /*
/example/models/XmlNestedUnionStruct+Codable.swift
/example/models/XmlNestedUnionStruct.swift
/example/models/XmlUnionShape+Codable.swift
/example/models/XmlUnionShape.swift
/example/models/XmlUnionsInput+BodyMiddleware.swift
/example/models/XmlUnionsInput+Encodable.swift
/example/models/XmlUnionsInput+HeaderMiddleware.swift
/example/models/XmlUnionsInput+QueryItemMiddleware.swift
/example/models/XmlUnionsInput.swift
/example/models/XmlUnionsInputBody+Decodable.swift
/example/models/XmlUnionsOutput.swift
/example/models/XmlUnionsOutputError.swift
         */
        val contents = getFileContents(context.manifest, "/example/models/XmlUnionShape+Codable.swift")
        val expectedContents =
            """

            """.trimIndent()

        contents.shouldContainOnlyOnce(expectedContents)
    }
    private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
        val context = TestContext.initContextFrom(smithyFile, serviceShapeId, MockHttpRestXMLProtocolGenerator()) { model ->
            model.defaultSettings(serviceShapeId, "RestXml", "2019-12-16", "Rest Xml Protocol")
        }
        context.generator.generateCodableConformanceForNestedTypes(context.generationCtx)
        context.generator.generateSerializers(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}