import io.kotest.matchers.string.shouldContain
import org.junit.jupiter.api.Assertions
import org.junit.jupiter.api.Test
import software.amazon.smithy.build.MockManifest
import software.amazon.smithy.swift.codegen.SwiftCodegenPlugin

class IntEnumGeneratorTests {

    @Test
    fun `generates int enum`() {
        val model = javaClass.getResource("int-enum-shape-test.smithy").asSmithy()
        val manifest = MockManifest()
        val context = buildMockPluginContext(model, manifest, "smithy.example#Example")
        SwiftCodegenPlugin().execute(context)
        val enumShape = manifest
            .getFileString("example/models/Abcs.swift").get()
        Assertions.assertNotNull(enumShape)
        var expectedGeneratedEnum = """
public enum Abcs: Swift.Equatable, Swift.RawRepresentable, Swift.CaseIterable, Swift.Hashable {
    case a
    case b
    case c
    case sdkUnknown(Swift.Int)

    public static var allCases: [Abcs] {
        return [
            .a,
            .b,
            .c,
            .sdkUnknown(0)
        ]
    }

    public init(rawValue: Swift.Int) {
        let value = Self.allCases.first(where: { ${'$'}0.rawValue == rawValue })
        self = value ?? Self.sdkUnknown(rawValue)
    }

    public var rawValue: Swift.Int {
        switch self {
        case .a: return 1
        case .b: return 2
        case .c: return 3
        case let .sdkUnknown(s): return s
        }
    }
}
"""
        enumShape.shouldContain(expectedGeneratedEnum)
    }
}
