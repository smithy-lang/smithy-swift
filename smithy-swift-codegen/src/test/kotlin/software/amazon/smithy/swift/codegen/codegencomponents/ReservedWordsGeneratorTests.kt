package software.amazon.smithy.swift.codegen.codegencomponents

/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test
import software.amazon.smithy.swift.codegen.TestContext
import software.amazon.smithy.swift.codegen.getFileContents

class ReservedWordsGeneratorTests {
    @Test
    fun `test enum`() {
        val context = setupTests("reserved-name-enum-test.smithy", "com.test#Example")
        val contents = getFileContents(context.manifest, "Sources/example/models/ReservedWordsEnum.swift")
        val expectedContents = """
extension ExampleClientTypes {

    public enum ReservedWordsEnum: Swift.Sendable, Swift.Equatable, Swift.RawRepresentable, Swift.CaseIterable, Swift.Hashable {
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
                .protocol
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
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it handles type name that conflicts with swift metatype`() {
        val context = setupTests("reserved-name-enum-test.smithy", "com.test#Example")
        val contents = getFileContents(context.manifest, "Sources/example/models/Type.swift")
        val expectedContents = """
extension ExampleClientTypes {

    public enum ModelType: Swift.Sendable, Swift.Equatable, Swift.RawRepresentable, Swift.CaseIterable, Swift.Hashable {
        case foo
        case test
        case sdkUnknown(Swift.String)

        public static var allCases: [ModelType] {
            return [
                .foo,
                .test
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
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it handles protocol name that conflicts with swift metatype`() {
        val context = setupTests("reserved-name-enum-test.smithy", "com.test#Example")
        val contents = getFileContents(context.manifest, "Sources/example/models/Protocol.swift")
        val expectedContents = """
extension ExampleClientTypes {

    public enum ModelProtocol: Swift.Sendable, Swift.Equatable, Swift.RawRepresentable, Swift.CaseIterable, Swift.Hashable {
        case bar
        case foo
        case sdkUnknown(Swift.String)

        public static var allCases: [ModelProtocol] {
            return [
                .bar,
                .foo
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
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    private fun setupTests(
        smithyFile: String,
        serviceShapeId: String,
    ): TestContext {
        val context = TestContext.initContextFrom(smithyFile, serviceShapeId)
        context.generator.generateSerializers(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
