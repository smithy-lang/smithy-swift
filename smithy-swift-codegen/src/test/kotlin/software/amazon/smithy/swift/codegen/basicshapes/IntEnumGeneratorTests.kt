package software.amazon.smithy.swift.codegen.basicshapes

/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.string.shouldContain
import org.junit.jupiter.api.Assertions
import org.junit.jupiter.api.Test
import software.amazon.smithy.build.MockManifest
import software.amazon.smithy.swift.codegen.SwiftCodegenPlugin
import software.amazon.smithy.swift.codegen.asSmithy
import software.amazon.smithy.swift.codegen.buildMockPluginContext

class IntEnumGeneratorTests {
    @Test
    fun `generates int enum`() {
        val model = javaClass.classLoader.getResource("int-enum-shape-test.smithy").asSmithy()
        val manifest = MockManifest()
        val context = buildMockPluginContext(model, manifest, "smithy.example#Example")
        SwiftCodegenPlugin().execute(context)
        val enumShape =
            manifest
                .getFileString("Sources/example/models/Abcs.swift")
                .get()
        Assertions.assertNotNull(enumShape)
        var expectedGeneratedEnum = """
public enum Abcs: Swift.Sendable, Swift.Equatable, Swift.RawRepresentable, Swift.CaseIterable, Swift.Hashable {
    case a
    case b
    case c
    case sdkUnknown(Swift.Int)

    public static var allCases: [Abcs] {
        return [
            .a,
            .b,
            .c
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
