
import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test

class ReservedWordsGeneratorTests {
    @Test
    fun `test enum`() {
        val context = setupTests("reserved-name-enum-test.smithy", "com.test#Example")
        val contents = getFileContents(context.manifest, "/example/models/ReservedWordsEnum.swift")
        val expectedContents =
            """
        extension ExampleClientTypes {
            public enum ReservedWordsEnum: Swift.Equatable, Swift.RawRepresentable, Swift.CaseIterable, Swift.Codable, Swift.Hashable {
                case any
                case `open`
                case `self`
                case `protocol`
                case sdkUnknown(Swift.String)
        
                public static var allCases: [ReservedWordsEnum] {
                    return [
                        .any,
                        .open,
                        .self,
                        .protocol,
                        .sdkUnknown("")
                    ]
                }
                public init?(rawValue: Swift.String) {
                    let value = Self.allCases.first(where: { ${'$'}0.rawValue == rawValue })
                    self = value ?? Self.sdkUnknown(rawValue)
                }
                public var rawValue: Swift.String {
                    switch self {
                    case .any: return "Any"
                    case .open: return "OPEN"
                    case .self: return "Self"
                    case .protocol: return "PROTOCOL"
                    case let .sdkUnknown(s): return s
                    }
                }
                public init(from decoder: Swift.Decoder) throws {
                    let container = try decoder.singleValueContainer()
                    let rawValue = try container.decode(RawValue.self)
                    self = ReservedWordsEnum(rawValue: rawValue) ?? ReservedWordsEnum.sdkUnknown(rawValue)
                }
            }
        }
            """.trimIndent()

        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it handles type name that conflicts with swift metatype`() {
        val context = setupTests("reserved-name-enum-test.smithy", "com.test#Example")
        val contents = getFileContents(context.manifest, "/example/models/Type.swift")
        val expectedContents =
        """
        extension ExampleClientTypes {
            public enum ModelType: Swift.Equatable, Swift.RawRepresentable, Swift.CaseIterable, Swift.Codable, Swift.Hashable {
                case foo
                case test
                case sdkUnknown(Swift.String)
        
                public static var allCases: [ModelType] {
                    return [
                        .foo,
                        .test,
                        .sdkUnknown("")
                    ]
                }
                public init?(rawValue: Swift.String) {
                    let value = Self.allCases.first(where: { ${'$'}0.rawValue == rawValue })
                    self = value ?? Self.sdkUnknown(rawValue)
                }
                public var rawValue: Swift.String {
                    switch self {
                    case .foo: return "foo"
                    case .test: return "test"
                    case let .sdkUnknown(s): return s
                    }
                }
                public init(from decoder: Swift.Decoder) throws {
                    let container = try decoder.singleValueContainer()
                    let rawValue = try container.decode(RawValue.self)
                    self = ModelType(rawValue: rawValue) ?? ModelType.sdkUnknown(rawValue)
                }
            }
        }
        """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it handles protocol name that conflicts with swift metatype`() {
        val context = setupTests("reserved-name-enum-test.smithy", "com.test#Example")
        val contents = getFileContents(context.manifest, "/example/models/Protocol.swift")
        val expectedContents =
            """
            extension ExampleClientTypes {
                public enum ModelProtocol: Swift.Equatable, Swift.RawRepresentable, Swift.CaseIterable, Swift.Codable, Swift.Hashable {
                    case bar
                    case foo
                    case sdkUnknown(Swift.String)
            
                    public static var allCases: [ModelProtocol] {
                        return [
                            .bar,
                            .foo,
                            .sdkUnknown("")
                        ]
                    }
                    public init?(rawValue: Swift.String) {
                        let value = Self.allCases.first(where: { ${'$'}0.rawValue == rawValue })
                        self = value ?? Self.sdkUnknown(rawValue)
                    }
                    public var rawValue: Swift.String {
                        switch self {
                        case .bar: return "bar"
                        case .foo: return "foo"
                        case let .sdkUnknown(s): return s
                        }
                    }
                    public init(from decoder: Swift.Decoder) throws {
                        let container = try decoder.singleValueContainer()
                        let rawValue = try container.decode(RawValue.self)
                        self = ModelProtocol(rawValue: rawValue) ?? ModelProtocol.sdkUnknown(rawValue)
                    }
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it handles types that are lower cased and not metatypes`() {
        val context = setupTests("reserved-name-metatype-test.smithy", "com.test#Example")
        val contents = getFileContents(context.manifest, "/example/models/Protocol.swift")
        val expectedContents =
        """
        extension ExampleClientTypes {
            public enum `protocol`: Swift.Equatable, Swift.RawRepresentable, Swift.CaseIterable, Swift.Codable, Swift.Hashable {
                case bar
                case foo
                case sdkUnknown(Swift.String)
        
                public static var allCases: [`protocol`] {
                    return [
                        .bar,
                        .foo,
                        .sdkUnknown("")
                    ]
                }
                public init?(rawValue: Swift.String) {
                    let value = Self.allCases.first(where: { ${'$'}0.rawValue == rawValue })
                    self = value ?? Self.sdkUnknown(rawValue)
                }
                public var rawValue: Swift.String {
                    switch self {
                    case .bar: return "bar"
                    case .foo: return "foo"
                    case let .sdkUnknown(s): return s
                    }
                }
                public init(from decoder: Swift.Decoder) throws {
                    let container = try decoder.singleValueContainer()
                    let rawValue = try container.decode(RawValue.self)
                    self = `protocol`(rawValue: rawValue) ?? `protocol`.sdkUnknown(rawValue)
                }
            }
        }
        """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
        val context = TestContext.initContextFrom(smithyFile, serviceShapeId)
        context.generator.generateSerializers(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
