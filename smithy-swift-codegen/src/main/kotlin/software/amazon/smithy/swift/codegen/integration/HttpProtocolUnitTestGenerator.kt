/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.ServiceShape
import software.amazon.smithy.protocoltests.traits.HttpMessageTestCase
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.SwiftWriter

/**
 * Abstract base implementation for protocol test generators to extend in order to generate HttpMessageTestCase
 * specific protocol tests.
 *
 * @param T Specific HttpMessageTestCase the protocol test generator is for.
 */
abstract class HttpProtocolUnitTestGenerator<T : HttpMessageTestCase>
    protected constructor(
        builder: Builder<T>,
    ) {
        protected val ctx: ProtocolGenerator.GenerationContext = builder.ctx!!
        protected val symbolProvider: SymbolProvider = builder.symbolProvider!!
        protected var model: Model = builder.model!!
        private val testCases: List<T> = builder.testCases!!
        protected val operation: OperationShape = builder.operation!!
        protected val writer: SwiftWriter = builder.writer!!
        protected val httpProtocolCustomizable = builder.httpProtocolCustomizable!!
        protected val httpBindingResolver = builder.httpBindingResolver!!
        protected val serviceName: String = builder.serviceName!!
        abstract val baseTestClassName: String

        /**
         * Render a test class and unit tests for the specified [testCases]
         */
        fun renderTestClass(testClassName: String) {
            writer
                .write("")
                .openBlock("class $testClassName: $baseTestClassName {")
                .call {
                    // Codegen interceptor for retrieving serialization time for request tests.
                    if (testClassName.endsWith("RequestTest")) {
                        renderSerializationBenchmarkingHarness(writer)
                    }
                    if (testClassName.endsWith("ResponseTest")) {
                        renderDeserializationBenchmarkingHarness(writer)
                    }
                }
                // Codegen helper functions used for both serialization and deserialization benchmarks.
                .write("""
                    func logSerdeBenchmarkResult(_ message: String) {
                        let fileManager = FileManager.default
                        let path = fileManager.currentDirectoryPath + "/serde_benchmark_log.txt"

                        let line = message + "\n"

                        if fileManager.fileExists(atPath: path) {
                            if let handle = FileHandle(forWritingAtPath: path) {
                                handle.seekToEndOfFile()
                                handle.write(Data(line.utf8))
                                handle.closeFile()
                            }
                        } else {
                            fileManager.createFile(atPath: path, contents: Data(line.utf8))
                        }
                    }

                    func calculatePercentiles(_ measurements: [Double]) -> (p50: Double, p90: Double, p95: Double, p99: Double) {
                        let sorted = measurements.sorted()
                        let count = sorted.count
                        let nsPerSecond = 1_000_000_000.0

                        func percentile(_ p: Double) -> Double {
                            let index = p / 100.0 * Double(count - 1)
                            let lower = Int(floor(index))
                            let upper = Int(ceil(index))
                            if lower == upper {
                                return sorted[lower] * nsPerSecond
                            }
                            let fraction = index - Double(lower)
                            return (sorted[lower] * (1 - fraction) + sorted[upper] * fraction) * nsPerSecond
                        }

                        return (
                            p50: percentile(50),
                            p90: percentile(90),
                            p95: percentile(95),
                            p99: percentile(99)
                        )
                    }

                    func calculateAndFormatMetrics(from measurements: [Double], testID: String) -> String {
                        let runCount = 10000

                        // Calcluate mean
                        var sum = 0.0
                        for num in measurements {
                            sum += num
                        }
                        let mean = sum / Double(runCount)

                        // Calculate standard deviation
                        var diffSquaredSum = 0.0
                        for num in measurements {
                            diffSquaredSum += (num - mean) * (num - mean)
                        }
                        let sd = sqrt(diffSquaredSum / Double(runCount - 1))
                        let percentiles = calculatePercentiles(measurements)
                        return ""${'"'}
                        {
                            "id": "\(testID)",
                            "n": \(runCount),
                            "mean": \(mean * 1_000_000_000) ns,
                            "p50": \(percentiles.p50) ns,
                            "p90": \(percentiles.p90) ns,
                            "p95": \(percentiles.p95) ns,
                            "p99": \(percentiles.p99) ns,
                            "std_dev": \(sd * 1_000_000_000) ns
                        }
                        ""${'"'}
                    }
                    
                    class BoxedDouble {
                        var value: Double
                        init(_ value: Double) {
                            self.value = value
                        }
                    }
                """.trimIndent())
                .call {
                    for (test in testCases) {
                        renderTestFunction(test)
                    }
                }.closeBlock("}")
        }

        // Codegen interceptor and double reference type used for retrieving serialization time from operation context.
        fun renderSerializationBenchmarkingHarness(writer: SwiftWriter) {
            writer.addImport(SwiftDependency.SMITHY_HTTP_API.target)
            writer.write(
                """
                    class SerializationBenchmarkInterceptor<InputType, OutputType>: Interceptor {
                        typealias RequestType = HTTPRequest
                        typealias ResponseType = HTTPResponse

                        let serializationTime: BoxedDouble

                        public init(
                            _ serializationTime: BoxedDouble
                        ) {
                            self.serializationTime = serializationTime
                        }

                        func readAfterSerialization(context: some AfterSerialization<InputType, RequestType>) async throws {
                            let serializeDuration = context.getAttributes().get(key: AttributeKey<Double>(name: "SerializeDuration"))
                            serializationTime.value = serializeDuration ?? 0
                        }
                    }

                    class SerializationBenchmarkInterceptorProvider: HttpInterceptorProvider {
                        let serializationTime: BoxedDouble

                        public init(
                            _ serializationTime: BoxedDouble
                        ) {
                            self.serializationTime = serializationTime
                        }
                      func create<InputType, OutputType>() -> any Interceptor<InputType, OutputType, HTTPRequest, HTTPResponse> {
                        return SerializationBenchmarkInterceptor(serializationTime)
                      }
                    }
                """.trimIndent()
            )
        }

        // Codegen interceptor and double reference type used for retrieving deserialization time from operation context.
        fun renderDeserializationBenchmarkingHarness(writer: SwiftWriter) {
            writer.addImport(SwiftDependency.SMITHY_HTTP_API.target)
            writer.addImport(SwiftDependency.SMITHY.target)
            writer.write(
                """
                        class DeserializationBenchmarkInterceptor<InputType, OutputType>: Interceptor {
                            typealias RequestType = HTTPRequest
                            typealias ResponseType = HTTPResponse
                            
                            let deserializationTime: BoxedDouble
                            
                            public init(
                                _ deserializationTime: BoxedDouble
                            ) {
                                self.deserializationTime = deserializationTime
                            }
                            
                            func readAfterDeserialization(
                                context: some AfterDeserialization<InputType, OutputType, RequestType, ResponseType>
                            ) async throws {
                                let deserializeDuration = context.getAttributes().get(key: AttributeKey<Double>(name: "DeserializeDuration"))
                                deserializationTime.value = deserializeDuration ?? 0
                            }
                        }
                        
                        class DeserializationBenchmarkInterceptorProvider: HttpInterceptorProvider {
                            let deserializationTime: BoxedDouble
                        
                            public init(
                                _ deserializationTime: BoxedDouble
                            ) {
                                self.deserializationTime = deserializationTime
                            }
                          func create<InputType, OutputType>() -> any Interceptor<InputType, OutputType, HTTPRequest, HTTPResponse> {
                            return DeserializationBenchmarkInterceptor(deserializationTime)
                          }
                        }
                    """.trimIndent()
            )
        }
        /**
         * Write a single unit test function using the given [writer]
         */
        private fun renderTestFunction(test: T) {
            test.documentation.ifPresent {
                writer.writeDocs(it)
            }

            writer.openBlock("func test${test.id}() async throws {", "}") {
                renderTestBody(test)
            }
        }

        /**
         * Render the body of a unit test
         */
        protected abstract fun renderTestBody(test: T)

        abstract class Builder<T : HttpMessageTestCase> {
            var ctx: ProtocolGenerator.GenerationContext? = null
            var symbolProvider: SymbolProvider? = null
            var model: Model? = null
            var testCases: List<T>? = null
            var service: ServiceShape? = null
            var operation: OperationShape? = null
            var writer: SwiftWriter? = null
            var serviceName: String? = null
            var httpProtocolCustomizable: HTTPProtocolCustomizable? = null
            var httpBindingResolver: HttpBindingResolver? = null

            fun symbolProvider(provider: SymbolProvider): Builder<T> = apply { this.symbolProvider = provider }

            fun model(model: Model): Builder<T> = apply { this.model = model }

            fun testCases(testCases: List<T>): Builder<T> = apply { this.testCases = testCases }

            fun ctx(ctx: ProtocolGenerator.GenerationContext): Builder<T> = apply { this.ctx = ctx }

            fun operation(operation: OperationShape): Builder<T> = apply { this.operation = operation }

            fun writer(writer: SwiftWriter): Builder<T> = apply { this.writer = writer }

            fun serviceName(serviceName: String): Builder<T> = apply { this.serviceName = serviceName }

            fun httpProtocolCustomizable(httpProtocolCustomizable: HTTPProtocolCustomizable): Builder<T> =
                apply {
                    this.httpProtocolCustomizable =
                        httpProtocolCustomizable
                }

            fun httpBindingResolver(httpBindingResolver: HttpBindingResolver): Builder<T> =
                apply {
                    this.httpBindingResolver =
                        httpBindingResolver
                }

            abstract fun build(): HttpProtocolUnitTestGenerator<T>
        }
    }
