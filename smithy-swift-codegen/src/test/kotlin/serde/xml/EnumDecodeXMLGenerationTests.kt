/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package serde.xml

import MockHttpRestXMLProtocolGenerator
import TestContext
import defaultSettings
import getFileContents
import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test

class EnumDecodeXMLGenerationTests {

    @Test
    fun `decode enum`() {
        val context = setupTests("Isolated/Restxml/xml-enums.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlEnumsOutputResponseBody+Decodable.swift")
        val expectedContents = """
        struct XmlEnumsOutputResponseBody: Swift.Equatable {
            let fooEnum1: RestXmlProtocolClientTypes.FooEnum?
            let fooEnum2: RestXmlProtocolClientTypes.FooEnum?
            let fooEnum3: RestXmlProtocolClientTypes.FooEnum?
            let fooEnumList: [RestXmlProtocolClientTypes.FooEnum]?
        }
        
        extension XmlEnumsOutputResponseBody: Swift.Decodable {
            enum CodingKeys: Swift.String, Swift.CodingKey {
                case fooEnum1
                case fooEnum2
                case fooEnum3
                case fooEnumList
            }
        
            public init (from decoder: Swift.Decoder) throws {
                let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                let fooEnum1Decoded = try containerValues.decodeIfPresent(RestXmlProtocolClientTypes.FooEnum.self, forKey: .fooEnum1)
                fooEnum1 = fooEnum1Decoded
                let fooEnum2Decoded = try containerValues.decodeIfPresent(RestXmlProtocolClientTypes.FooEnum.self, forKey: .fooEnum2)
                fooEnum2 = fooEnum2Decoded
                let fooEnum3Decoded = try containerValues.decodeIfPresent(RestXmlProtocolClientTypes.FooEnum.self, forKey: .fooEnum3)
                fooEnum3 = fooEnum3Decoded
                if containerValues.contains(.fooEnumList) {
                    struct KeyVal0{struct member{}}
                    let fooEnumListWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: CollectionMemberCodingKey<KeyVal0.member>.CodingKeys.self, forKey: .fooEnumList)
                    if let fooEnumListWrappedContainer = fooEnumListWrappedContainer {
                        let fooEnumListContainer = try fooEnumListWrappedContainer.decodeIfPresent([RestXmlProtocolClientTypes.FooEnum].self, forKey: .member)
                        var fooEnumListBuffer:[RestXmlProtocolClientTypes.FooEnum]? = nil
                        if let fooEnumListContainer = fooEnumListContainer {
                            fooEnumListBuffer = [RestXmlProtocolClientTypes.FooEnum]()
                            for stringContainer0 in fooEnumListContainer {
                                fooEnumListBuffer?.append(stringContainer0)
                            }
                        }
                        fooEnumList = fooEnumListBuffer
                    } else {
                        fooEnumList = []
                    }
                } else {
                    fooEnumList = nil
                }
            }
        }
        """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `decode enum nested`() {
        val context = setupTests("Isolated/Restxml/xml-enums.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlEnumsNestedOutputResponseBody+Decodable.swift")
        val expectedContents =
            """
            struct XmlEnumsNestedOutputResponseBody: Swift.Equatable {
                let nestedEnumsList: [[RestXmlProtocolClientTypes.FooEnum]]?
            }
            
            extension XmlEnumsNestedOutputResponseBody: Swift.Decodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case nestedEnumsList
                }
            
                public init (from decoder: Swift.Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    if containerValues.contains(.nestedEnumsList) {
                        struct KeyVal0{struct member{}}
                        let nestedEnumsListWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: CollectionMemberCodingKey<KeyVal0.member>.CodingKeys.self, forKey: .nestedEnumsList)
                        if let nestedEnumsListWrappedContainer = nestedEnumsListWrappedContainer {
                            let nestedEnumsListContainer = try nestedEnumsListWrappedContainer.decodeIfPresent([[RestXmlProtocolClientTypes.FooEnum]].self, forKey: .member)
                            var nestedEnumsListBuffer:[[RestXmlProtocolClientTypes.FooEnum]]? = nil
                            if let nestedEnumsListContainer = nestedEnumsListContainer {
                                nestedEnumsListBuffer = [[RestXmlProtocolClientTypes.FooEnum]]()
                                var listBuffer0: [RestXmlProtocolClientTypes.FooEnum]? = nil
                                for listContainer0 in nestedEnumsListContainer {
                                    listBuffer0 = [RestXmlProtocolClientTypes.FooEnum]()
                                    for stringContainer1 in listContainer0 {
                                        listBuffer0?.append(stringContainer1)
                                    }
                                    if let listBuffer0 = listBuffer0 {
                                        nestedEnumsListBuffer?.append(listBuffer0)
                                    }
                                }
                            }
                            nestedEnumsList = nestedEnumsListBuffer
                        } else {
                            nestedEnumsList = []
                        }
                    } else {
                        nestedEnumsList = nil
                    }
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }
    private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
        val context = TestContext.initContextFrom(smithyFile, serviceShapeId, MockHttpRestXMLProtocolGenerator()) { model ->
            model.defaultSettings(serviceShapeId, "RestXml", "2019-12-16", "Rest Xml Protocol")
        }
        context.generator.generateDeserializers(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
