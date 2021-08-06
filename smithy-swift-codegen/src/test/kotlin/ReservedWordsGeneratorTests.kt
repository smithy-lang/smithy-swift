
import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test

class ReservedWordsGeneratorTests {
    @Test
    fun `test enum`() {
        val context = setupTests("reserved-name-enum-test.smithy", "com.test#Example")
        val contents = getFileContents(context.manifest, "/example/models/ReservedWordsEnum.swift")
        val expectedContents =
            """
            public enum ReservedWordsEnum {
                case any
                case `open`
                case `self`
                case `protocol`
                case sdkUnknown(Swift.String)
            }
            
            extension ReservedWordsEnum : Swift.Equatable, Swift.RawRepresentable, Swift.CaseIterable, Swift.Codable, Swift.Hashable {
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
