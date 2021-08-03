package software.amazon.smithy.aws.swift.codegen.awsquery

import TestContext
import defaultSettings
import getFileContents
import io.kotest.matchers.string.shouldContainOnlyOnce
import mocks.MockHttpAWSQueryProtocolGenerator
import org.junit.jupiter.api.Test
import shouldSyntacticSanityCheck

class MapEncodeFormURLGeneratorTests {
    @Test
    fun `001 encode different types of maps`() {
        val context = setupTests("Isolated/formurl/query-maps.smithy", "aws.protocoltests.query#AwsQuery")
        val contents = getFileContents(context.manifest, "/Example/models/QueryMapsInput+Encodable.swift")
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            extension QueryMapsInput: Encodable, Reflection {
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: Key.self)
                    if let complexMapArg = complexMapArg {
                        var complexMapArgContainer = container.nestedContainer(keyedBy: Key.self, forKey: Key("ComplexMapArg"))
                        for (index0, element0) in complexMapArg.sorted(by: { ${'$'}0.key < ${'$'}1.key }).enumerated() {
                            let stringKey0 = element0.key
                            let greetingstructValue0 = element0.value
                            var entryContainer0 = complexMapArgContainer.nestedContainer(keyedBy: Key.self, forKey: Key("entry.\(index0.advanced(by: 1))"))
                            var keyContainer0 = entryContainer0.nestedContainer(keyedBy: Key.self, forKey: Key("key"))
                            try keyContainer0.encode(stringKey0, forKey: Key(""))
                            var valueContainer0 = entryContainer0.nestedContainer(keyedBy: Key.self, forKey: Key("value"))
                            try valueContainer0.encode(greetingstructValue0, forKey: Key(""))
                        }
                    }
                    if let flattenedMap = flattenedMap {
                        if !flattenedMap.isEmpty {
                            for (index0, element0) in flattenedMap.sorted(by: { ${'$'}0.key < ${'$'}1.key }).enumerated() {
                                let stringKey0 = element0.key
                                let stringValue0 = element0.value
                                var nestedContainer0 = container.nestedContainer(keyedBy: Key.self, forKey: Key("FlattenedMap.\(index0.advanced(by: 1))"))
                                var keyContainer0 = nestedContainer0.nestedContainer(keyedBy: Key.self, forKey: Key("key"))
                                try keyContainer0.encode(stringKey0, forKey: Key(""))
                                var valueContainer0 = nestedContainer0.nestedContainer(keyedBy: Key.self, forKey: Key("value"))
                                try valueContainer0.encode(stringValue0, forKey: Key(""))
                            }
                        }
                    }
                    if let flattenedMapWithXmlName = flattenedMapWithXmlName {
                        if !flattenedMapWithXmlName.isEmpty {
                            for (index0, element0) in flattenedMapWithXmlName.sorted(by: { ${'$'}0.key < ${'$'}1.key }).enumerated() {
                                let stringKey0 = element0.key
                                let stringValue0 = element0.value
                                var nestedContainer0 = container.nestedContainer(keyedBy: Key.self, forKey: Key("Hi.\(index0.advanced(by: 1))"))
                                var keyContainer0 = nestedContainer0.nestedContainer(keyedBy: Key.self, forKey: Key("K"))
                                try keyContainer0.encode(stringKey0, forKey: Key(""))
                                var valueContainer0 = nestedContainer0.nestedContainer(keyedBy: Key.self, forKey: Key("V"))
                                try valueContainer0.encode(stringValue0, forKey: Key(""))
                            }
                        }
                    }
                    if let mapArg = mapArg {
                        var mapArgContainer = container.nestedContainer(keyedBy: Key.self, forKey: Key("MapArg"))
                        for (index0, element0) in mapArg.sorted(by: { ${'$'}0.key < ${'$'}1.key }).enumerated() {
                            let stringKey0 = element0.key
                            let stringValue0 = element0.value
                            var entryContainer0 = mapArgContainer.nestedContainer(keyedBy: Key.self, forKey: Key("entry.\(index0.advanced(by: 1))"))
                            var keyContainer0 = entryContainer0.nestedContainer(keyedBy: Key.self, forKey: Key("key"))
                            try keyContainer0.encode(stringKey0, forKey: Key(""))
                            var valueContainer0 = entryContainer0.nestedContainer(keyedBy: Key.self, forKey: Key("value"))
                            try valueContainer0.encode(stringValue0, forKey: Key(""))
                        }
                    }
                    if let mapOfLists = mapOfLists {
                        var mapOfListsContainer = container.nestedContainer(keyedBy: Key.self, forKey: Key("MapOfLists"))
                        for (index0, element0) in mapOfLists.sorted(by: { ${'$'}0.key < ${'$'}1.key }).enumerated() {
                            let stringKey0 = element0.key
                            let stringlistValue0 = element0.value
                            var entryContainer0 = mapOfListsContainer.nestedContainer(keyedBy: Key.self, forKey: Key("entry.\(index0.advanced(by: 1))"))
                            var keyContainer0 = entryContainer0.nestedContainer(keyedBy: Key.self, forKey: Key("key"))
                            try keyContainer0.encode(stringKey0, forKey: Key(""))
                            var valueContainer1 = entryContainer0.nestedContainer(keyedBy: Key.self, forKey: Key("value"))
                            for (index1, string1) in stringlistValue0.enumerated() {
                                try valueContainer1.encode(string1, forKey: Key("member.\(index1.advanced(by: 1))"))
                            }
                        }
                    }
                    if let mapWithXmlMemberName = mapWithXmlMemberName {
                        var mapWithXmlMemberNameContainer = container.nestedContainer(keyedBy: Key.self, forKey: Key("MapWithXmlMemberName"))
                        for (index0, element0) in mapWithXmlMemberName.sorted(by: { ${'$'}0.key < ${'$'}1.key }).enumerated() {
                            let stringKey0 = element0.key
                            let stringValue0 = element0.value
                            var entryContainer0 = mapWithXmlMemberNameContainer.nestedContainer(keyedBy: Key.self, forKey: Key("entry.\(index0.advanced(by: 1))"))
                            var keyContainer0 = entryContainer0.nestedContainer(keyedBy: Key.self, forKey: Key("K"))
                            try keyContainer0.encode(stringKey0, forKey: Key(""))
                            var valueContainer0 = entryContainer0.nestedContainer(keyedBy: Key.self, forKey: Key("V"))
                            try valueContainer0.encode(stringValue0, forKey: Key(""))
                        }
                    }
                    if let renamedMapArg = renamedMapArg {
                        var renamedMapArgContainer = container.nestedContainer(keyedBy: Key.self, forKey: Key("Foo"))
                        for (index0, element0) in renamedMapArg.sorted(by: { ${'$'}0.key < ${'$'}1.key }).enumerated() {
                            let stringKey0 = element0.key
                            let stringValue0 = element0.value
                            var entryContainer0 = renamedMapArgContainer.nestedContainer(keyedBy: Key.self, forKey: Key("entry.\(index0.advanced(by: 1))"))
                            var keyContainer0 = entryContainer0.nestedContainer(keyedBy: Key.self, forKey: Key("key"))
                            try keyContainer0.encode(stringKey0, forKey: Key(""))
                            var valueContainer0 = entryContainer0.nestedContainer(keyedBy: Key.self, forKey: Key("value"))
                            try valueContainer0.encode(stringValue0, forKey: Key(""))
                        }
                    }
                    try container.encode("QueryMaps", forKey:Key("Action"))
                    try container.encode("2020-01-08", forKey:Key("Version"))
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
        val context = TestContext.initContextFrom(smithyFile, serviceShapeId, MockHttpAWSQueryProtocolGenerator()) { model ->
            model.defaultSettings(serviceShapeId, "Example", "2020-01-08", "aws query protocol")
        }
        context.generator.generateCodableConformanceForNestedTypes(context.generationCtx)
        context.generator.generateSerializers(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
