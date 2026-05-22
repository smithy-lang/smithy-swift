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

fun ServiceShape.hasSerdePerformanceTests(model: Model): Boolean {
    return allOperations
        .map { model.expectShape(it) }
        .map {
            listOf(
                it.getTrait<HttpRequestTestsTrait>()?.testCases?.map { it.tags },
                it.getTrait<HttpResponseTestsTrait>()?.testCases?.map { it.tags }
            )
                .mapNotNull { it } }
        .flatten()
        .flatten()
        .flatten()
        .any { it == "serde-benchmark" }
}