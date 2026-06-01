package software.amazon.smithy.swift.codegen.utils

import software.amazon.smithy.aws.traits.ServiceTrait
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.ServiceShape
import software.amazon.smithy.protocoltests.traits.HttpRequestTestsTrait
import software.amazon.smithy.protocoltests.traits.HttpResponseTestsTrait
import software.amazon.smithy.swift.codegen.model.getTrait

// Utility function for returning sdkId from service
val ServiceShape.sdkId: String?
    get() = getTrait<ServiceTrait>()?.sdkId

fun ServiceShape.hasSerdePerformanceTests(model: Model): Boolean =
    allOperations
        .map { model.expectShape(it) }
        .map {
            listOf(
                it.getTrait<HttpRequestTestsTrait>()?.testCases ?: listOf(),
                it.getTrait<HttpResponseTestsTrait>()?.testCases ?: listOf(),
            ).flatten()
        }
        .flatten()
        .any { it.isSerdeBenchmarkTest }
